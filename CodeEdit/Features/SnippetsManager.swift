//
//  SnippetsManager.swift
//  CodeEdit
//
//  Created by Austin Condiff on 1/7/25.
//

import Foundation

class SnippetManager: ObservableObject {
    static let shared = SnippetManager()

    @Published var userSnippets: [Snippet] = []
    @Published var extensionSnippets: [Snippet] = []

    var allSnippets: [Snippet] {
        userSnippets + extensionSnippets
    }

    private init() {
        loadSnippets()
    }

    func addUserSnippet(_ snippet: Snippet) {
        userSnippets.append(snippet)
        saveSnippets()
    }

    func removeUserSnippet(_ snippet: Snippet) {
        userSnippets.removeAll { $0.id == snippet.id }
        saveSnippets()
    }

    private func loadSnippets() {
        // Load user-defined snippets from a file (e.g., `~/Library/Application Support/CodeEdit/Snippets.json`)
        let snippetsFileURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/CodeEdit/Snippets.json")
        guard let data = try? Data(contentsOf: snippetsFileURL),
              let snippets = try? JSONDecoder().decode([Snippet].self, from: data) else {
            return
        }
        userSnippets = snippets
    }

    private func saveSnippets() {
        // Save user-defined snippets to a file
        let snippetsFileURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/CodeEdit/Snippets.json")
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        guard let data = try? encoder.encode(userSnippets) else { return }
        try? data.write(to: snippetsFileURL)
    }
}
