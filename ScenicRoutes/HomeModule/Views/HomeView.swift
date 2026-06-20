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
    @EnvironmentObject private var router: Router
    @State private var viewport: Viewport = .camera(
        center: CLLocationCoordinate2D(latitude: 42.0987, longitude: -75.9180),
        zoom: 13
    )
    
    var body: some View {
        ZStack {
            // Map / route layer
            switch viewModel.viewState {
            case .idle:
                idleMap
            case .loading:
                idleMap
                ProgressView("Finding route...")
                    .padding(20)
                    .background(AppTheme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.15), radius: 10)
            case .loaded(let t):
                NavigationPreviewView(
                    navigationRoutes: t,
                    navigationProvider: viewModel.navigationProvider,
                    onRouteSelected: { newRoutes in
                        viewModel.updateSelectedRoutes(newRoutes)
                    }
                ).ignoresSafeArea()
                VStack {
                    Spacer()
                    if viewModel.canNavigate {
                        Button {
                            router.presentFullScreen(.navigation)
                        } label: {
                            HStack {
                                Image(systemName: "location.north.fill")
                                Text("Start Navigation")
                                    .fontWeight(.bold)
                            }
                            .font(.system(size: 17))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: AppTheme.accent.opacity(0.4), radius: 10, y: 4)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    } else {
                        Text("Preview only — navigation starts from your location")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.black.opacity(0.65))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.bottom, 30)
                    }
                }
            case .error(let string):
                idleMap
                Text(string)
                    .foregroundStyle(.white)
                    .padding()
                    .background(AppTheme.accent.opacity(0.9))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Top input layer
            VStack {
                if viewModel.hasStartedRouting {
                    routeFieldsCard
                } else {
                    searchBar
                }
                Spacer()
            }
        }
        .onAppear {
            viewModel.startLocationUpdates()
        }
        .fullScreenCover(item: $router.presentedFullScreen) { route in
            switch route {
            case .navigation:
                if case .loaded(let routes) = viewModel.viewState {
                    TurnByTurnView(
                        navigationRoutes: routes,
                        navigationProvider: viewModel.navigationProvider
                    )
                    .ignoresSafeArea()
                }
            }
        }
        .sheet(item: $router.presentedSheet) { route in
            switch route {
            case .search(let field):
                SearchView(viewModel: viewModel)
                    .onAppear {
                        viewModel.activeSearchField = field
                    }
            }
        }
    }
    
    // MARK: - Browse mode: single search bar
    private var searchBar: some View {
        Button {
            viewModel.activeSearchField = .destination
            router.presentSheet(.search(.destination))
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.primary)
                Text("Where to?")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: AppTheme.primary.opacity(0.18), radius: 12, y: 4)
        }
        .padding()
    }
    
    // MARK: - Route mode: source/destination card
    private var routeFieldsCard: some View {
        HStack(spacing: 12) {
            // Back button
            Button {
                viewModel.resetRouting()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.primary)
            }
            
            // Fields
            VStack(spacing: 10) {
                fieldRow(
                    icon: "circle.fill",
                    iconColor: AppTheme.success,
                    text: viewModel.sourceText,
                    placeholder: "Choose source"
                ) {
                    viewModel.activeSearchField = .source
                    router.presentSheet(.search(.source))
                }
                
                fieldRow(
                    icon: "mappin.circle.fill",
                    iconColor: AppTheme.accent,
                    text: viewModel.destinationText,
                    placeholder: "Choose destination"
                ) {
                    viewModel.activeSearchField = .destination
                    router.presentSheet(.search(.destination))
                }
            }
            
            // Swap button
            Button {
                viewModel.swapSourceAndDestination()
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(AppTheme.primary)
                    .clipShape(Circle())
                    .shadow(color: AppTheme.primary.opacity(0.4), radius: 6, y: 2)
            }
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.12), radius: 14, y: 4)
        .padding()
    }
    
    // MARK: - Reusable field row
    private func fieldRow(icon: String, iconColor: Color, text: String, placeholder: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
                Text(text.isEmpty ? placeholder : text)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(text.isEmpty ? AppTheme.textSecondary : AppTheme.textPrimary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(AppTheme.fieldBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Idle map
    private var idleMap: some View {
        Map(viewport: $viewport) {
            Puck2D(bearing: .heading)
        }
        .ignoresSafeArea()
        .onChange(of: viewModel.currentUserLocation) { _, newLocation in
            if newLocation != nil {
                viewport = .followPuck(zoom: 14)
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(Router())
}

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
