//
//  Editor+StateRestoration.swift
//  CodeEdit
//
//  Created by Khan Winter on 7/3/23.
//

import Foundation
import SwiftUI
import OrderedCollections

struct EditorRestorationState: Codable {
    var focus: Editor
    var groups: EditorSplit
}

extension EditorSplit: Codable {
    fileprivate enum EditorSplitType: String, Codable {
        case one
        case vertical
        case horizontal
    }

    enum CodingKeys: String, CodingKey {
        case type
        case tabs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(EditorSplitType.self, forKey: .type)
        switch type {
        case .one:
            let editor = try container.decode(Editor.self, forKey: .tabs)
            self = .one(editor)
        case .vertical:
            let editor = try container.decode(SplitViewData.self, forKey: .tabs)
            self = .vertical(editor)
        case .horizontal:
            let editor = try container.decode(SplitViewData.self, forKey: .tabs)
            self = .horizontal(editor)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .one(data):
            try container.encode(EditorSplitType.one, forKey: .type)
            try container.encode(data, forKey: .tabs)
        case let .vertical(data):
            try container.encode(EditorSplitType.vertical, forKey: .type)
            try container.encode(data, forKey: .tabs)
        case let .horizontal(data):
            try container.encode(EditorSplitType.horizontal, forKey: .type)
            try container.encode(data, forKey: .tabs)
        }
    }
}

extension SplitViewData: Codable {
    fileprivate enum SplitViewAxis: String, Codable {
        case vertical, horizontal

        init(_ swiftUI: Axis) {
            switch swiftUI {
            case .vertical: self = .vertical
            case .horizontal: self = .horizontal
            }
        }

        var swiftUI: Axis {
            switch self {
            case .vertical: return .vertical
            case .horizontal: return .horizontal
            }
        }
    }

    enum CodingKeys: String, CodingKey {
        case editorSplits
        case axis
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let axis = try container.decode(SplitViewAxis.self, forKey: .axis).swiftUI
        let editorSplits = try container.decode([EditorSplit].self, forKey: .editorSplits)
        self.init(axis, editorSplits: editorSplits)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(editorSplits, forKey: .editorSplits)
        try container.encode(SplitViewAxis(axis), forKey: .axis)
    }
}

extension Editor: Codable {
    enum CodingKeys: String, CodingKey {
        case tabs
        case selectedTab
        case id
    }

    convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let fileURLs = try container.decode([URL].self, forKey: .tabs)
        let selectedTab = try? container.decode(URL.self, forKey: .selectedTab)
        let id = try container.decode(UUID.self, forKey: .id)
        self.init(
            files: OrderedSet(fileURLs.map { CEWorkspaceFile(url: $0) }),
            selectedTab: selectedTab == nil ? nil : CEWorkspaceFile(url: selectedTab!),
            parent: nil
        )
        self.id = id
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tabs.map { $0.url }, forKey: .tabs)
        try container.encode(selectedTab?.url, forKey: .selectedTab)
        try container.encode(id, forKey: .id)
    }
}
