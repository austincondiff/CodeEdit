//
//  InternalDevelopmentInspectorView.swift
//  CodeEdit
//
//  Created by Austin Condiff on 2/19/24.
//

import SwiftUI

struct InternalDevelopmentInspectorView: View {
    var body: some View {
        Form {
            if #available(macOS 14.0, *) {
                Section("Performance") {
//                    LabeledContent("FPS") {
                    FPSView()
//                    }
                }
            }
            InternalDevelopmentNotificationsView()
        }
    }
}
