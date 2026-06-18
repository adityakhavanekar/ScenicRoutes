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

@MainActor
class RouteViewModel: ObservableObject {
    @Published var navigationRoutes: NavigationRoutes?
    
    let binghamton = CLLocationCoordinate2D(latitude: 42.0987, longitude: -75.9180)
    let newYork = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    
    let navigationProvider = MapboxNavigationProvider(coreConfig: .init())
    
    func fetchRoute() {
        let options = NavigationRouteOptions(coordinates: [binghamton, newYork])
        
        Task {
            let request = navigationProvider.mapboxNavigation.routingProvider().calculateRoutes(options: options)
            switch await request.result {
            case .success(let routes):
                self.navigationRoutes = routes
                print("routes loaded successfully")
            case .failure(let error):
                print("Error getting routes: \(error.localizedDescription)")
            }
        }
    }
}
