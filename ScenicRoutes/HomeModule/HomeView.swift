//
//  HomeView.swift
//  ScenicRoutes
//
//  Created by Aditya Khavanekar on 6/17/26.
//

import SwiftUI
import MapboxMaps

struct HomeView: View {
    
    let binghamton = CLLocationCoordinate2D(latitude: 42.0987, longitude: -75.9180)
    let nyc = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
    
    var body: some View {
        Map(initialViewport: .camera(center: midpoint, zoom: 7, bearing: 0, pitch: 0)) {
            CircleAnnotation(centerCoordinate: binghamton)
                .circleColor(StyleColor(.red))
                .circleRadius(8)
            
            CircleAnnotation(centerCoordinate: nyc)
                .circleColor(StyleColor(.blue))
                .circleRadius(8)
        }.ignoresSafeArea()
    }
    var midpoint: CLLocationCoordinate2D {
        CLLocationCoordinate2D(
            latitude: (binghamton.latitude + nyc.latitude) / 2,
            longitude: (binghamton.longitude + nyc.longitude) / 2
        )
    }
    
}

#Preview {
    HomeView()
}
