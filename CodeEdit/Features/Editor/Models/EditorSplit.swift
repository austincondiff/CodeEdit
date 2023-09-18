//
//  EditorSplit.swift
//  CodeEdit
//
//  Created by Wouter Hennen on 06/02/2023.
//

import Foundation

enum EditorSplit {
    case one(Editor)
    case vertical(SplitViewData)
    case horizontal(SplitViewData)

    /// Closes all tabs which present the given file
    /// - Parameter file: a file.
    func closeAllTabs(of file: CEWorkspaceFile) {
        switch self {
        case .one(let editor):
            editor.tabs.remove(file)
        case .vertical(let data), .horizontal(let data):
            data.editorSplits.forEach {
                $0.closeAllTabs(of: file)
            }
        }
    }

    /// Returns some editor, except the given editor.
    /// - Parameter except: the search will exclude this editor.
    /// - Returns: Some editor.
    func findSomeEditor(except: Editor? = nil) -> Editor? {
        switch self {
        case .one(let editor) where editor != except:
            return editor
        case .vertical(let data), .horizontal(let data):
            for editorSplit in data.editorSplits {
                if let result = editorSplit.findSomeEditor(except: except), result != except {
                    return result
                }
            }
            return nil
        default:
            return nil
        }
    }

    /// Forms a set of all files currently represented by tabs.
    func gatherOpenFiles() -> Set<CEWorkspaceFile> {
        switch self {
        case .one(let editor):
            return Set(editor.tabs)
        case .vertical(let data), .horizontal(let data):
            return data.editorSplits.map { $0.gatherOpenFiles() }.reduce(into: []) { $0.formUnion($1) }
        }
    }

    /// Flattens the splitviews.
    mutating func flatten(parent: SplitViewData) {
        switch self {
        case .one:
            break
        case .horizontal(let data), .vertical(let data):
            if data.editorSplits.count == 1 {
                let one = data.editorSplits[0]
                if case .one(let editor) = one {
                    editor.parent = parent
                }
                self = one
            } else {
                data.flatten()
            }
        }
    }
}
