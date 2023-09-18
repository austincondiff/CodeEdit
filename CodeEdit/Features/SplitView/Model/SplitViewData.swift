//
//  SplitViewData.swift
//  CodeEdit
//
//  Created by Wouter Hennen on 16/02/2023.
//

import SwiftUI

final class SplitViewData: ObservableObject {
    @Published var editorSplits: [EditorSplit]

    var axis: Axis

    init(_ axis: Axis, editorSplits: [EditorSplit] = []) {
        self.editorSplits = editorSplits
        self.axis = axis

        editorSplits.forEach {
            if case .one(let editor) = $0 {
                editor.parent = self
            }
        }
    }

    /// Splits the editor at a certain index into two separate editors.
    /// - Parameters:
    ///   - direction: direction in which the editor will be split.
    ///   If the direction is the same as the ancestor direction,
    ///   the editor is added to the ancestor instead of creating a new split container.
    ///   - index: index where the divider will be added.
    ///   - editor: new editor class that will be used for the editor.
    func split(_ direction: Edge, at index: Int, new editor: Editor) {
        editor.parent = self
        switch (axis, direction) {
        case (.horizontal, .trailing), (.vertical, .bottom):
            editorSplits.insert(.one(editor), at: index+1)

        case (.horizontal, .leading), (.vertical, .top):
            editorSplits.insert(.one(editor), at: index)

        case (.horizontal, .top):
            editorSplits[index] = .vertical(.init(.vertical, editorSplits: [.one(editor), editorSplits[index]]))

        case (.horizontal, .bottom):
            editorSplits[index] = .vertical(.init(.vertical, editorSplits: [editorSplits[index], .one(editor)]))

        case (.vertical, .leading):
            editorSplits[index] = .horizontal(.init(.horizontal, editorSplits: [.one(editor), editorSplits[index]]))

        case (.vertical, .trailing):
            editorSplits[index] = .horizontal(.init(.horizontal, editorSplits: [editorSplits[index], .one(editor)]))
        }
    }

    /// Closes an Editor.
    /// - Parameter id: ID of the Editor.
    func closeEditor(with id: Editor.ID) {
        editorSplits.removeAll { editorSplit in
            if case .one(let editor) = editorSplit {
                if editor.id == id {
                    return true
                }
            }

            return false
        }
    }

    func getEditorSplit(with id: Editor.ID) -> EditorSplit? {
        for editorSplit in editorSplits {
            if case .one(let editor) = editorSplit {
                if editor.id == id {
                    return editorSplit
                }
            }
        }

        return nil
    }

    /// Flattens the splitviews.
    func flatten() {
        for index in editorSplits.indices {
            editorSplits[index].flatten(parent: self)
        }
    }
}
