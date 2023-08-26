//
//  DebugAreaView.swift
//  CodeEditModules/StatusBar
//
//  Created by Lukas Pistrol on 22.03.22.
//

import SwiftUI

struct DebugAreaView: View {
    @Environment(\.colorScheme)
    private var colorScheme

    @EnvironmentObject private var model: DebugAreaViewModel

    @State var selection: DebugAreaTab? = .terminal

    var items: [DebugAreaTab] = [
        .terminal, .debugConsole, .output
    ]

    var body: some View {
        ZStack {
            ForEach(items) { item in
                item
                    .disabled(item != selection)
                    .opacity(item == selection ? 1 : 0)
                    .environment(\.tabSelected, item == selection)
            }
        }
        .safeAreaInset(edge: .leading, spacing: 0) {
            HStack(spacing: 0) {
                AreaTabBar(items: DebugAreaTab.allCases, selection: $selection, position: .side)
                Divider()
                    .overlay(Color(nsColor: colorScheme == .dark ? .black : .clear))
            }
        }
        .overlay(alignment: .bottomTrailing) {
            HStack(spacing: 5) {
                Divider()
                HStack(spacing: 0) {
                    Button {
                        model.isMaximized.toggle()
                    } label: {
                        Image(systemName: "arrowtriangle.up.square")
                    }
                    .buttonStyle(.icon(isActive: model.isMaximized, size: 24))
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 8)
            .frame(maxHeight: 27)
        }
    }
}

struct TabSelectedKey: EnvironmentKey {
    static var defaultValue: Bool = false
}

extension EnvironmentValues {
    var tabSelected: Bool {
        get { self[TabSelectedKey.self] }
        set { self[TabSelectedKey.self] = newValue }
    }
}
