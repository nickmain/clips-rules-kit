// Copyright (c) 2024 David N Main

import SwiftUI

@main
struct CLIPSRunnerApp: App {
    var body: some Scene {
        DocumentGroup(newDocument: CLIPSRunnerDocument()) { file in
            ContentView(document: file.document)
        }
    }
}
