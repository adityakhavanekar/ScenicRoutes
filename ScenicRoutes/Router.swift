//
//  Router.swift
//  ScenicRoutes
//
//  Created by Aditya Khavanekar on 6/19/26.
//

import SwiftUI
import Combine

enum Route: Hashable{
    case settings
}

enum SheetRoute: Identifiable {
    case search(SearchField)
    var id: String { String(describing: self) }
}

enum FullScreenRoute:Identifiable{
    case navigation
    var id:String {String(describing:self)}
}

@MainActor
final class Router: ObservableObject{
    @Published var path = NavigationPath()
    @Published var presentedFullScreen: FullScreenRoute?
    @Published var presentedSheet: SheetRoute?
    
    func push(_ route: Route){
        path.append(route)
    }
    
    func pop(){
        guard !path.isEmpty else {return}
        path.removeLast()
    }
    
    func popToRoot(){
        path = NavigationPath()
    }
    
    func presentFullScreen(_ route: FullScreenRoute){
        presentedFullScreen = route
    }
    
    func dismissFullScreen(){
        presentedFullScreen = nil
    }
    
    func presentSheet(_ route: SheetRoute) {
        presentedSheet = route
    }

    func dismissSheet() {
        presentedSheet = nil
    }
}
