// Copyright (c) 2024 David N Main

import CLIPSRules
import SwiftUI

struct ContentView: View {
    @State var document: CLIPSRunnerDocument
    @State var content = ""

    init(document: CLIPSRunnerDocument) {
        self.document = document
        _content = State(initialValue: document.content.body)
    }

    var body: some View {
        NavigationStack {
            TextEditor(text: $content)
                .font(.system(size: 24, design: .monospaced))
        }
        .onChange(of: content) { old, new in
            document.content.body = content
        }
    }
}

#Preview {
    ContentView(document: CLIPSRunnerDocument())
}
