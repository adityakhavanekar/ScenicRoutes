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
    
    var body: some View {
        ZStack {
            switch viewModel.viewState {
            case .idle, .loading:
                ProgressView("Enter source and destination")
            case .loaded(let t):
                NavigationPreviewView(
                    navigationRoutes: t,
                    navigationProvider: viewModel.navigationProvider
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
                Text(string)
                    .foregroundStyle(.red)
                    .padding()
            }
            
            VStack {
                VStack(spacing: 10) {
                    // Two fields on the left, swap button centered on the right
                    HStack(spacing: 10) {
                        VStack(spacing: 10) {
                            // Source field
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
                            
                            // Destination field
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
                        
                        // Swap button centered to the right of both fields
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
                    
                    // Find route
                    Button {
                        viewModel.fetchRoute()
                    } label: {
                        Text("Find Route")
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.15), radius: 8)
                .padding()
                
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
