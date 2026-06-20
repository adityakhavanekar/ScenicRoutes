//
//  RouteViewModel.swift
//  ScenicRoutes
//
//  Created by Aditya Khavanekar on 6/17/26.
//

import SwiftUI
import MapboxNavigationCore
import MapboxDirections
import CoreLocation
import Combine
import MapboxSearch

enum ViewStates<T>{
    case idle
    case loading
    case loaded(T)
    case error(String)
}

enum SearchField {
    case source
    case destination
}

@MainActor
class RouteViewModel: ObservableObject {
    @Published var viewState: ViewStates<NavigationRoutes> = .idle
    @Published var sourceText = ""
    @Published var destinationText = ""
    @Published var canNavigate = false
    @Published var searchSuggestions: [PlaceAutocomplete.Suggestion] = []
    @Published var searchQuery = ""
    @Published var currentUserLocation: CLLocationCoordinate2D?
    @Published var hasStartedRouting = false
    private var sourceCoordinate: CLLocationCoordinate2D?
    private var destinationCoordinate: CLLocationCoordinate2D?
    private var cancellables = Set<AnyCancellable>()

    private let placeAutocomplete = PlaceAutocomplete()
    private let locationManager = LocationManager()
    var activeSearchField: SearchField = .source
    let navigationProvider = MapboxNavigationProvider(coreConfig: .init())
    
    init() {
        $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in
                self?.fetchSuggestions(for: query)
            }
            .store(in: &cancellables)
        
        locationManager.$currentLocation
            .receive(on: RunLoop.main)
            .assign(to: &$currentUserLocation)
    }
    
    func fetchSuggestions(for query: String) {
        guard !query.isEmpty else {
            searchSuggestions = []
            return
        }
        placeAutocomplete.suggestions(for: query) { [weak self] result in
            switch result {
            case .success(let suggestions):
                self?.searchSuggestions = suggestions
            case .failure(let error):
                print("Suggestions failed: \(error.localizedDescription)")
                self?.searchSuggestions = []
            }
        }
    }
    
    func selectFreeText(_ query: String) async {
        guard let coordinate = await geocode(query) else {
            print("Couldn't geocode: \(query)")
            return
        }
        switch activeSearchField {
        case .source:
            sourceText = query
            sourceCoordinate = coordinate
        case .destination:
            destinationText = query
            destinationCoordinate = coordinate
        }
        onSelectionChanged()
    }
    
    func selectSearchResult(_ suggestion: PlaceAutocomplete.Suggestion) {
        placeAutocomplete.select(suggestion: suggestion) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let placeResult):
                let coordinate = placeResult.coordinate
                let name = suggestion.name
                switch self.activeSearchField {
                case .source:
                    self.sourceText = name
                    self.sourceCoordinate = coordinate
                case .destination:
                    self.destinationText = name
                    self.destinationCoordinate = coordinate
                }
                self.onSelectionChanged()
            case .failure(let error):
                print("Selection failed: \(error.localizedDescription)")
            }
        }
    }
    
    // Called after any source/destination selection
    func onSelectionChanged() {
        if !destinationText.isEmpty {
            if sourceText.isEmpty {
                sourceText = "Current Location"
                sourceCoordinate = locationManager.currentLocation   // 👈 add this
            }
            hasStartedRouting = true
            fetchRoute()
        }
    }
    
    func startLocationUpdates() {
        locationManager.requestLocation()
    }
    
    func useMyCurrentLocation() {
        sourceText = "Current Location"
        sourceCoordinate = locationManager.currentLocation   // 👈 add this
        onSelectionChanged()
    }
    
    // Reset back to browse mode
    func resetRouting() {
        hasStartedRouting = false
        sourceText = ""
        destinationText = ""
        sourceCoordinate = nil
        destinationCoordinate = nil
        canNavigate = false
        viewState = .idle
    }
    
    func fetchRoute() {
        guard let sourceCoord = sourceCoordinate, let destCoord = destinationCoordinate else {
            viewState = .error("Missing location coordinates")
            return
        }

        viewState = .loading

        Task {
            if let current = locationManager.currentLocation {
                let sourceLoc = CLLocation(latitude: sourceCoord.latitude, longitude: sourceCoord.longitude)
                let currentLoc = CLLocation(latitude: current.latitude, longitude: current.longitude)
                canNavigate = sourceLoc.distance(from: currentLoc) < 150
            } else {
                canNavigate = false
            }

            let options = NavigationRouteOptions(coordinates: [sourceCoord, destCoord])
            let request = navigationProvider.mapboxNavigation.routingProvider().calculateRoutes(options: options)
            switch await request.result {
            case .success(let routes):
                viewState = .loaded(routes)
                print("routes loaded successfully")
            case .failure(let error):
                viewState = .error("Error: \(error.localizedDescription)")
                print("Error getting routes: \(error.localizedDescription)")
            }
        }
    }
    
    func geocode(_ query: String) async -> CLLocationCoordinate2D? {
        await withCheckedContinuation { continuation in
            placeAutocomplete.suggestions(for: query) { result in
                switch result{
                case .success(let suggestions):
                    guard let first = suggestions.first else {
                        continuation.resume(returning: nil)
                        return
                    }
                    self.placeAutocomplete
                        .select(suggestion: first) { selectionResult in
                            switch selectionResult{
                            case .success(let placeResult):
                                continuation.resume(returning: placeResult.coordinate)
                            case .failure(let error):
                                print("Select failed: \(error.localizedDescription)")
                                continuation.resume(returning: nil)
                            }
                        }
                case .failure(let error):
                    print("Suggestions failed: \(error.localizedDescription)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func swapSourceAndDestination() {
        swap(&sourceText, &destinationText)
        swap(&sourceCoordinate, &destinationCoordinate)
        if hasStartedRouting {
            fetchRoute()
        }
    }
}
