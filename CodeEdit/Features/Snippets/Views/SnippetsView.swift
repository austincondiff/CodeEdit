//
//  SnippetsView.swift
//  CodeEdit
//
//  Created by Austin Condiff on 1/7/25.
//

import SwiftUI

struct SnippetsView: View {
    @ObservedObject private var viewModel: SnippetsViewModel
    private let onClose: () -> Void
    private let insertSnippet: (Snippet) -> Void

    @State private var selectedSnippet: Snippet?

    init(viewModel: SnippetsViewModel, onClose: @escaping () -> Void, insertSnippet: @escaping (Snippet) -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
        self.insertSnippet = insertSnippet
    }

    var body: some View {
        SearchPanelView(
            title: "Snippets",
            image: Image(systemName: "line.3.horizontal.decrease.circle"),
            options: $viewModel.filteredSnippets,
            text: $viewModel.searchQuery,
            alwaysShowOptions: true
        ) { snippet in
            SnippetListItemView(snippet: snippet)
        } preview: { snippet in
            SnippetPreviewView(snippet: snippet)
        } onRowClick: { snippet in
            insertSnippet(snippet)
            viewModel.searchQuery = ""
            onClose()
        } onClose: {
            onClose()
        }
    }
}

struct SnippetListItemView: View {
    let snippet: Snippet

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(snippet.title).font(.headline)
            Text(snippet.description).font(.subheadline).foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

struct SnippetPreviewView: View {
    let snippet: Snippet

    var body: some View {
        VStack(alignment: .leading) {
            Text("Snippet Preview")
                .font(.headline)
                .padding(.bottom, 8)
            Text(snippet.code)
                .font(.system(.body, design: .monospaced))
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
    }
}
