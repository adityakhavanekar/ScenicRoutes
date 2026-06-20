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
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 4)
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
                                    .fontWeight(.semibold)
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    } else {
                        Text("Preview only — navigation starts from your location")
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.bottom, 30)
                    }
                }
            case .error(let string):
                idleMap
                Text(string)
                    .foregroundStyle(.white)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Top input layer: single search (browse) OR source/destination (route mode)
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
    
    // Browse mode: single search bar
    private var searchBar: some View {
        Button {
            viewModel.activeSearchField = .destination
            router.presentSheet(.search(.destination))
        } label: {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)
                Text("Search destination")
                    .foregroundStyle(.gray)
                Spacer()
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.15), radius: 6)
        }
        .padding()
    }
    
    // Route mode: source/destination fields with swap + back
    private var routeFieldsCard: some View {
        VStack(spacing: 10) {
            HStack {
                Button {
                    viewModel.resetRouting()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(.black)
                }
                Spacer()
            }
            
            HStack(spacing: 10) {
                VStack(spacing: 10) {
                    Button {
                        viewModel.activeSearchField = .source
                        router.presentSheet(.search(.source))
                    } label: {
                        HStack {
                            Image(systemName: "circle")
                                .foregroundStyle(.green)
                            Text(viewModel.sourceText.isEmpty ? "Choose source" : viewModel.sourceText)
                                .foregroundStyle(viewModel.sourceText.isEmpty ? Color.gray : Color.black)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(white: 0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    Button {
                        viewModel.activeSearchField = .destination
                        router.presentSheet(.search(.destination))
                    } label: {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundStyle(.red)
                            Text(viewModel.destinationText.isEmpty ? "Choose destination" : viewModel.destinationText)
                                .foregroundStyle(viewModel.destinationText.isEmpty ? Color.gray : Color.black)
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color(white: 0.95))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                Button {
                    viewModel.swapSourceAndDestination()
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundStyle(.blue)
                        .padding(8)
                        .background(Color(white: 0.95))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.15), radius: 8)
        .padding()
    }
    
    private var idleMap: some View {
        Map(viewport: $viewport) {
            Puck2D(bearing: .heading)
        }
        .ignoresSafeArea()
        .onChange(of: viewModel.currentUserLocation) { _, newLocation in
            if let loc = newLocation {
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
