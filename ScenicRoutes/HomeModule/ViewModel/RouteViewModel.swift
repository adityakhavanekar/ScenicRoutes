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
            case .failure(let error):
                print("Selection failed: \(error.localizedDescription)")
            }
        }
    }
    
    // Call on app launch so current location is ready
    func startLocationUpdates() {
        locationManager.requestLocation()
    }
    
    // Convenience: fill source as current location
    func useMyCurrentLocation() {
        sourceText = "Current Location"
        locationManager.requestLocation()
    }
    
    func fetchRoute() {
        viewState = .loading
        
        Task {
            let sourceCoord: CLLocationCoordinate2D
            if sourceText == "Current Location", let current = locationManager.currentLocation {
                sourceCoord = current
            } else {
                guard let geocoded = await geocode(sourceText) else {
                    viewState = .error("Couldnt find source location")
                    return
                }
                sourceCoord = geocoded
            }
            
            guard let destCoord = await geocode(destinationText) else {
                viewState = .error("Couldnt find destination location")
                return
            }
            
            // Distance check: is the source near the user's actual location?
            if let current = locationManager.currentLocation {
                let sourceLoc = CLLocation(latitude: sourceCoord.latitude, longitude: sourceCoord.longitude)
                let currentLoc = CLLocation(latitude: current.latitude, longitude: current.longitude)
                canNavigate = sourceLoc.distance(from: currentLoc) < 150  // within 150 meters
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
                                continuation
                                    .resume(returning: placeResult.coordinate)
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
    }
}
