//
//  EditorSplitView.swift
//  CodeEdit
//
//  Created by Wouter Hennen on 20/02/2023.
//

import SwiftUI

struct EditorSplitView: View {
    var split: EditorSplit

    @FocusState.Binding var focus: Editor?

    @Environment(\.window)
    private var window

    @Environment(\.isAtEdge)
    private var isAtEdge

    var toolbarHeight: CGFloat {
        window.contentView?.safeAreaInsets.top ?? .zero
    }

    var body: some View {
        VStack {
            switch split {
            case .one(let detailEditor):
                EditorView(editor: detailEditor, focus: $focus)
                    .transformEnvironment(\.edgeInsets) { insets in
                        switch isAtEdge {
                        case .all:
                            insets.top += toolbarHeight
                            insets.bottom += StatusBarView.height + 5
                        case .top:
                            insets.top += toolbarHeight
                        case .bottom:
                            insets.bottom += StatusBarView.height + 5
                        default:
                            return
                        }
                    }
            case .vertical(let data), .horizontal(let data):
                ChildEditorSplitView(data: data, focus: $focus)
            }
        }
    }

    struct ChildEditorSplitView: View {
        @ObservedObject var data: SplitViewData

        @FocusState.Binding var focus: Editor?

        var body: some View {
            SplitView(axis: data.axis) {
                splitView
            }
            .edgesIgnoringSafeArea([.top, .bottom])
        }

        var splitView: some View {
            ForEach(Array(data.editorSplits.enumerated()), id: \.offset) { index, item in
                EditorSplitView(split: item, focus: $focus)
                    .transformEnvironment(\.isAtEdge) { belowToolbar in
                        calcIsAtEdge(current: &belowToolbar, index: index)
                    }
                    .environment(\.splitEditor) { [weak data] edge, newEditor in
                        data?.split(edge, at: index, new: newEditor)
                    }
            }
        }

        func calcIsAtEdge(current: inout VerticalEdge.Set, index: Int) {
            if case .vertical = data.axis {
                guard data.editorSplits.count != 1 else { return }
                if index == data.editorSplits.count - 1 {
                    current.remove(.top)
                } else if index == 0 {
                    current.remove(.bottom)
                } else {
                    current = []
                }
            }
        }
    }
}

private struct BelowToolbarEnvironmentKey: EnvironmentKey {
    static var defaultValue: VerticalEdge.Set = .all
}

extension EnvironmentValues {
    fileprivate var isAtEdge: BelowToolbarEnvironmentKey.Value {
        get { self[BelowToolbarEnvironmentKey.self] }
        set { self[BelowToolbarEnvironmentKey.self] = newValue }
    }
}
