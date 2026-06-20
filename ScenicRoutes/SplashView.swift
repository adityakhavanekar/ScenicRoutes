//
//  SplashView.swift
//  ScenicRoutes
//
//  Created by Aditya Khavanekar on 6/20/26.
//

import SwiftUI

struct SplashView: View {
    var body: some View {
        ZStack {
            // Full-screen scenic photo
            Image("splashScreen")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Subtle dark gradient at top for text readability
            LinearGradient(
                colors: [Color.black.opacity(0.45), Color.clear],
                startPoint: .top,
                endPoint: .center
            )
            .ignoresSafeArea()

            // App name near the top (over the open sky)
            VStack {
                Spacer().frame(height: 80)
                Text("ScenicRoutes")
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.4), radius: 6, y: 2)
                Text("The beautiful way there")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .shadow(color: .black.opacity(0.4), radius: 4, y: 1)
                Spacer()
            }
        }
    }
}

#Preview {
    SplashView()
}
