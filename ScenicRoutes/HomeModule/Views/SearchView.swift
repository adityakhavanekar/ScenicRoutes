import SwiftUI
import MapboxSearch

struct SearchView: View {
    @ObservedObject var viewModel: RouteViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.gray)
                TextField("Search for a place", text: $viewModel.searchQuery)
                    .autocorrectionDisabled()
                    .onSubmit {
                        submitFreeText()
                    }
                Button("Cancel") {
                    viewModel.searchQuery = ""
                    viewModel.searchSuggestions = []
                    dismiss()
                }
            }
            .padding()
            .background(Color(.systemGray6))

            // "Use Current Location" — only when searching source
            if viewModel.activeSearchField == .source {
                Button {
                    viewModel.useMyCurrentLocation()
                    viewModel.searchQuery = ""
                    viewModel.searchSuggestions = []
                    dismiss()
                } label: {
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundStyle(.blue)
                        Text("Use Current Location")
                            .foregroundStyle(.blue)
                        Spacer()
                    }
                    .padding()
                }
                Divider()
            }

            // Suggestions list
            List(Array(viewModel.searchSuggestions.enumerated()), id: \.offset) { index, suggestion in
                Button {
                    selectSuggestion(suggestion)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(suggestion.name)
                            .foregroundStyle(.primary)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private func selectSuggestion(_ suggestion: PlaceAutocomplete.Suggestion) {
        viewModel.selectSearchResult(suggestion)
        viewModel.searchQuery = ""
        viewModel.searchSuggestions = []
        dismiss()
    }

    private func submitFreeText() {
        let query = viewModel.searchQuery
        guard !query.isEmpty else { return }
        Task {
            await viewModel.selectFreeText(query)
            viewModel.searchQuery = ""
            viewModel.searchSuggestions = []
            dismiss()
        }
    }
}
