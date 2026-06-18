//
//  HomeView.swift
//  ScenicRoutes
//
//  Created by Aditya Khavanekar on 6/17/26.
//

import SwiftUI
import MapboxMaps

struct HomeView: View {
    
    @StateObject var viewModel = RouteViewModel()
    
    let binghamton = CLLocationCoordinate2D(latitude: 42.0987, longitude: -75.9180)
    let nyc = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    
    var body: some View {
        ZStack{
            if let routes = viewModel.navigationRoutes{
                NavigationPreviewView(
                    navigationRoutes: routes,
                    navigationProdvider: viewModel.navigationProvider
                )
                .ignoresSafeArea()
            }else{
                ProgressView("Loading route")
            }
        }
        .onAppear{
            viewModel.fetchRoute()
        }
    }
}

#Preview {
    HomeView()
}
