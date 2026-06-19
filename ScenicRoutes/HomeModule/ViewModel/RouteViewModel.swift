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

@MainActor
class RouteViewModel: ObservableObject {
    @Published var viewState: ViewStates<NavigationRoutes> = .idle
    @Published var sourceText = ""
    @Published var destinationText = ""
    @Published var canNavigate = false
    
    private let placeAutocomplete = PlaceAutocomplete()
    private let locationManager = LocationManager()
    let navigationProvider = MapboxNavigationProvider(coreConfig: .init())
    
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
}
