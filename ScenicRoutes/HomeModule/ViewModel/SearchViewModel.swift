//
//  SearchViewModel.swift
//  ScenicRoutes
//
//  Created by Aditya Khavanekar on 6/17/26.
//

import SwiftUI
import Combine
import MapKit


@MainActor
class SearchViewModel: NSObject,ObservableObject {
    @Published var queryText = ""
    @Published var suggestions: [MKLocalSearchCompletion] = []

    private var cancellables = Set<AnyCancellable>()
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = .address
    }
}

extension SearchViewModel: MKLocalSearchCompleterDelegate {

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter){
        Task { @MainActor in
            self.suggestions = completer.results
        }
    }
    
    nonisolated func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: any Error
    ) {
        print("Search error: \(error)")
    }
}
