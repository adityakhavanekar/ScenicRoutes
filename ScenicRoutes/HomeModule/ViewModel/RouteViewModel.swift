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
    
    private let placeAutocomplete = PlaceAutocomplete()
    let navigationProvider = MapboxNavigationProvider(coreConfig: .init())
    
    func fetchRoute() {
        viewState = .loading
        
        Task {
            guard let sourceCoord = await geocode(sourceText) else {
                viewState = .error("Couldnt find source location")
                return
            }
            guard let destCoord = await geocode(destinationText) else {
                viewState = .error("Couldnt find destination location")
                return
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
