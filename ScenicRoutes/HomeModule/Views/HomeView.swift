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
        ZStack{
            switch viewModel.viewState {
            case .idle,.loading:
                ProgressView("Enter source and destination")
            case .loaded(let t):
                NavigationPreviewView(
                    navigationRoutes: t,
                    navigationProvider: viewModel.navigationProvider
                ).ignoresSafeArea()
            case .error(let string):
                Text(string)
                    .foregroundStyle(.red)
                    .padding()
            }
            
            VStack(spacing: 8) {
                TextField("Source", text: $viewModel.sourceText)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 2)
                
                TextField("Destination", text: $viewModel.destinationText)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .shadow(radius: 2)
                
                Button {
                    viewModel.fetchRoute()
                } label: {
                    Text("Find Route")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    HomeView()
}

//VStack {
//    Spacer()
//    Button {
//        print("Navigation clicked")
//    } label: {
//        HStack {
//            Image(systemName: "location.north.fill")
//            Text("Start Navigation")
//                .fontWeight(.semibold)
//        }
//        .foregroundStyle(.white)
//        .frame(maxWidth: .infinity)
//        .padding()
//        .background(Color.blue)
//        .clipShape(RoundedRectangle(cornerRadius: 14))
//    }
//    .padding(.horizontal)
//    .padding(.bottom, 30)
//}
