//
//  Snippet.swift
//  CodeEdit
//
//  Created by Austin Condiff on 1/7/25.
//

import Foundation

struct Snippet: Identifiable, Hashable, Codable {
    let id: UUID
    let title: String
    let description: String
    let code: String
    let language: String // Programming language (e.g., Swift, Python, etc.)
    let availability: SnippetAvailability // Availability of the snippet
    let completion: String // Completion keyword or trigger for snippet insertion

    init(
        id: UUID = UUID(),
        title: String,
        description: String,
        code: String,
        language: String,
        availability: SnippetAvailability,
        completion: String
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.code = code
        self.language = language
        self.availability = availability
        self.completion = completion
    }
}

enum SnippetAvailability: String, Codable {
    case classImplementation = "Class Implementation"
    case codeExpression = "Code Expression"
    case functionOrMethod = "Function or Method"
    case stringOrComment = "String or Comment"
    case topLevel = "Top Level"
}
