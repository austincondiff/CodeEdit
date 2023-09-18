//
//  TabManager.swift
//  CodeEdit
//
//  Created by Wouter Hennen on 03/03/2023.
//

import Combine
import Foundation
import DequeModule
import OrderedCollections

class EditorManager: ObservableObject {
    /// The root editor split.
    @Published var editorSplit: EditorSplit

    @Published var isFocusingActiveEditor: Bool

    /// The Editor with active focus.
    @Published var activeEditor: Editor {
        didSet {
            activeEditorHistory.prepend { [weak oldValue] in oldValue }
            switchToActiveEditor()
        }
    }

    /// History of last-used editors.
    var activeEditorHistory: Deque<() -> Editor?> = []

    var fileDocuments: [CEWorkspaceFile: CodeFileDocument] = [:]

    /// notify listeners whenever tab selection changes on the active editor.
    var tabBarTabIdSubject = PassthroughSubject<String?, Never>()
    var cancellable: AnyCancellable?

    init() {
        let tab = Editor()
        self.activeEditor = tab
        self.activeEditorHistory.prepend { [weak tab] in tab }
        self.editorSplit = .horizontal(.init(.horizontal, editorSplits: [.one(tab)]))
        self.isFocusingActiveEditor = false
        switchToActiveEditor()
    }

    /// Flattens the splitviews.
    func flatten() {
        if case .horizontal(let data) = editorSplit {
            data.flatten()
        }
    }

    /// Opens a new tab in a editor.
    /// - Parameters:
    ///   - item: The tab to open.
    ///   - editor: The editor to add the tab to. If nil, it is added to the active tab group.
    func openTab(item: CEWorkspaceFile, in editor: Editor? = nil) {
        let editor = editor ?? activeEditor
        editor.openTab(item: item)
    }

    /// bind active tap group to listen to file selection changes.
    func switchToActiveEditor() {
        cancellable?.cancel()
        cancellable = nil
        cancellable = activeEditor.$selectedTab
            .sink { [weak self] tab in
                self?.tabBarTabIdSubject.send(tab?.id)
            }
    }

    /// Restores the tab manager from a captured state obtained using `saveRestorationState`
    /// - Parameter workspace: The workspace to retrieve state from.
    func restoreFromState(_ workspace: WorkspaceDocument) {
        guard let fileManager = workspace.workspaceFileManager,
              let data = workspace.getFromWorkspaceState(.openTabs) as? Data,
              let state = try? JSONDecoder().decode(EditorRestorationState.self, from: data) else {
            return
        }
        fixRestoredEditorSplit(state.groups, fileManager: fileManager)
        self.editorSplit = state.groups
        self.activeEditor = findEditorSplit(
            group: state.groups,
            searchFor: state.focus.id
        ) ?? editorSplit.findSomeEditor()!
        switchToActiveEditor()
    }

    /// Fix any hanging files after restoring from saved state.
    ///
    /// After decoding the state, we're left with `CEWorkspaceFile`s that don't exist in the file manager
    /// so this function maps all those to 'real' files. Works recursively on all the tab groups.
    /// - Parameters:
    ///   - group: The tab group to fix.
    ///   - fileManager: The file manager to use to map files.
    private func fixRestoredEditorSplit(_ group: EditorSplit, fileManager: CEWorkspaceFileManager) {
        switch group {
        case let .one(data):
            fixEditor(data, fileManager: fileManager)
        case let .vertical(splitData):
            splitData.editorSplits.forEach { group in
                fixRestoredEditorSplit(group, fileManager: fileManager)
            }
        case let .horizontal(splitData):
            splitData.editorSplits.forEach { group in
                fixRestoredEditorSplit(group, fileManager: fileManager)
            }
        }
    }

    private func findEditorSplit(group: EditorSplit, searchFor id: UUID) -> Editor? {
        switch group {
        case let .one(data):
            return data.id == id ? data : nil
        case let .vertical(splitData):
            return splitData.editorSplits.compactMap { findEditorSplit(group: $0, searchFor: id) }.first
        case let .horizontal(splitData):
            return splitData.editorSplits.compactMap { findEditorSplit(group: $0, searchFor: id) }.first
        }
    }

    /// Fixes any hanging files after restoring from saved state.
    /// - Parameters:
    ///   - data: The tab group to fix.
    ///   - fileManager: The file manager to use to map files.a
    private func fixEditor(_ editor: Editor, fileManager: CEWorkspaceFileManager) {
        editor.tabs = OrderedSet(editor.tabs.compactMap { fileManager.getFile($0.url.path) })
        if let selectedTab = editor.selectedTab {
            editor.selectedTab = fileManager.getFile(selectedTab.url.path)
        }
    }

    func saveRestorationState(_ workspace: WorkspaceDocument) {
        if let data = try? JSONEncoder().encode(
            EditorRestorationState(focus: activeEditor, groups: editorSplit)
        ) {
            workspace.addToWorkspaceState(key: .openTabs, value: data)
        } else {
            workspace.addToWorkspaceState(key: .openTabs, value: nil)
        }
    }
}
