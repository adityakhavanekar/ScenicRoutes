//
//  ScenicRoutesApp.swift
//  ScenicRoutes
//
//  Created by Aditya Khavanekar on 6/17/26.
//

import SwiftUI
import CoreData

@main
struct ScenicRoutesApp: App {
    
    @StateObject private var router = Router()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack(path: $router.path) {
                HomeView()
                    .navigationDestination(for: Route.self) { route in
                        switch route{
                        case .settings:
                            Text("Settings")
                        }
                    }
            }.environmentObject(router)
        }
    }
}
