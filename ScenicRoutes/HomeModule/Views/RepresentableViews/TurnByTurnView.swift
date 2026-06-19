//
//  TurnByTurnView.swift
//  ScenicRoutes
//
//  Created by Aditya Khavanekar on 6/18/26.
//

import SwiftUI
import MapboxNavigationCore
import MapboxNavigationUIKit

struct TurnByTurnView: UIViewControllerRepresentable{
    
    let navigationRoutes: NavigationRoutes
    let navigationProvider: MapboxNavigationProvider
    
    func makeUIViewController(context:Context) -> NavigationViewController{
        let navigationOptions = NavigationOptions(
            mapboxNavigation: navigationProvider.mapboxNavigation, voiceController: navigationProvider.routeVoiceController, eventsManager: navigationProvider
                .eventsManager()
        )
        return NavigationViewController(
            navigationRoutes: navigationRoutes,
            navigationOptions: navigationOptions
        )
    }
    
    func updateUIViewController(_ uiViewController: NavigationViewController, context: Context) {}
}
