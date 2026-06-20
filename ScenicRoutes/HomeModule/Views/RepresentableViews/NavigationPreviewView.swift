import SwiftUI
import MapboxNavigationCore
import MapboxMaps
import Combine
import MapboxDirections

struct NavigationPreviewView: UIViewRepresentable {
    let navigationRoutes: NavigationRoutes
    let navigationProvider: MapboxNavigationProvider
    var onRouteSelected: ((NavigationRoutes) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> NavigationMapView {
        let view = NavigationMapView(
            location: navigationProvider.mapboxNavigation.navigation().locationMatching
                .map(\.enhancedLocation)
                .eraseToAnyPublisher(),
            routeProgress: navigationProvider.mapboxNavigation.navigation().routeProgress
                .map(\.?.routeProgress)
                .eraseToAnyPublisher()
        )
        view.delegate = context.coordinator

        // Set an initial camera near the route's start so it never opens at the globe
        if let firstCoord = navigationRoutes.mainRoute.route.shape?.coordinates.first {
            view.mapView.mapboxMap.setCamera(to: CameraOptions(center: firstCoord, zoom: 6))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            view.showcase(navigationRoutes, animated: false)
        }
        return view
    }

    func updateUIView(_ uiView: NavigationMapView, context: Context) {
        // Keep the coordinator's routes in sync with what's displayed
        context.coordinator.currentRoutes = navigationRoutes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            uiView.showcase(navigationRoutes, animated: false)
        }
    }

    // MARK: - Coordinator (handles delegate callbacks)
    class Coordinator: NSObject, NavigationMapViewDelegate {
        let parent: NavigationPreviewView
        var currentRoutes: NavigationRoutes

        init(_ parent: NavigationPreviewView) {
            self.parent = parent
            self.currentRoutes = parent.navigationRoutes
        }

        func navigationMapView(_ navigationMapView: NavigationMapView, didSelect alternativeRoute: AlternativeRoute) {
            Task {
                if let updated = await currentRoutes.selecting(alternativeRoute: alternativeRoute) {
                    await MainActor.run {
                        self.currentRoutes = updated
                        navigationMapView.showcase(updated, animated: true)
                        parent.onRouteSelected?(updated)
                    }
                }
            }
        }
    }
}
