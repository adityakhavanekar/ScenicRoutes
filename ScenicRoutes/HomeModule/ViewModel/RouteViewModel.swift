//
//  RouteViewModel.swift
//  ScenicRoutes
//
//  Created by Aditya Khavanekar on 6/17/26.
//

import SwiftUI
import MapboxMaps
import MapboxDirections
import CoreLocation
import Combine

@MainActor
class RouteViewModel: ObservableObject {
    @Published var route: LineString?
    
    let binghamton = CLLocationCoordinate2D(latitude: 42.0987, longitude: -75.9180)
    let nyc = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    
    func fetchRoute() {
        let waypoints = [
            Waypoint(coordinate: binghamton, name: "Binghamton"),
            Waypoint(coordinate: nyc, name: "NYC")
        ]

        let options = RouteOptions(waypoints: waypoints, profileIdentifier: .automobile)
        options.routeShapeResolution = .full

        Directions.shared.calculate(options) { [weak self] _, result in
            switch result {
            case .failure(let error):
                print("Route error: \(error)")
            case .success(let response):
                if let coords = response.routes?.first?.shape?.coordinates {
                    self?.route = LineString(coords)
                    print("Route found: \(coords.count) coordinates")
                }
            }
        }
    }
}
