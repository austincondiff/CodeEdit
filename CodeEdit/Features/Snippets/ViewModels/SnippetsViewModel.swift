//
//  SnippetsViewModel.swift
//  CodeEdit
//
//  Created by Austin Condiff on 1/7/25.
//

import Foundation
import Combine

class SnippetsViewModel: ObservableObject {
    @Published var searchQuery: String = ""
    @Published var filteredSnippets: [Snippet] = []

    private let snippetManager: SnippetManager

    init(snippetManager: SnippetManager = .shared) {
        self.snippetManager = snippetManager
        self.filteredSnippets = snippetManager.allSnippets
        setupBindings()
    }

    func reset() {
        searchQuery = ""
//        selected = nil
//        filteredSnippets = SnippetManager.shared.snippets
    }

    private func setupBindings() {
        $searchQuery
            .debounce(for: .milliseconds(200), scheduler: DispatchQueue.main)
            .sink { [weak self] query in
                self?.filterSnippets(query: query)
            }
            .store(in: &cancellables)
    }

    private func filterSnippets(query: String) {
        filteredSnippets = snippetManager.allSnippets.filter {
            query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.description.localizedCaseInsensitiveContains(query)
        }
    }

    private var cancellables = Set<AnyCancellable>()
}
