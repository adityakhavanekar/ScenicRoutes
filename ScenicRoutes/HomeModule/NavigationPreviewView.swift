//
//  NavigationPreviewView.swift
//  ScenicRoutes
//
//  Created by Aditya Khavanekar on 6/18/26.
//

import SwiftUI
import MapboxNavigationCore
import MapboxMaps
import MapboxNavigationUIKit
import Combine

struct NavigationPreviewView: UIViewRepresentable{
    let navigationRoutes: NavigationRoutes
    let navigationProdvider: MapboxNavigationProvider
    
    func makeUIView(context: Context) -> NavigationMapView {
        let view = NavigationMapView(
            location: navigationProdvider.mapboxNavigation.navigation().locationMatching
                .map(\.enhancedLocation)
                .eraseToAnyPublisher(),
            routeProgress: navigationProdvider.mapboxNavigation.navigation().routeProgress
                .map(\.?.routeProgress)
                .eraseToAnyPublisher()
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            view.showcase(navigationRoutes, animated: true)
        }
        return view
    }
    
    func updateUIView(_ uiView: NavigationMapView, context: Context) {
        uiView.showcase(navigationRoutes, animated: true)
    }
}
