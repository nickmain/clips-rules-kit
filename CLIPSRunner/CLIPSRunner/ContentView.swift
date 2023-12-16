// Copyright (c) 2023 David N Main

import SwiftUI

struct RowModel: Identifiable {
    let id = UUID().uuidString
    let name: String
    let color: Color
}

struct ContentView: View {
    @Binding var document: CLIPSRunnerDocument
    @State private var users: [RowModel] = [
        .init(name: "Glenn", color: .green),
        .init(name: "Malcolm", color: .yellow),
        .init(name: "Nicola", color: .orange),
        .init(name: "Terri", color: .pink)
    ]
    @Environment(\.openURL) var openUrl

    var body: some View {

        HStack {
            TextEditor(text: $document.text)

            VStack {
                NavigationStack {
                    List($users, editActions: .move) { $user in
                        HStack {
                            Image(systemName: "figure.walk").foregroundColor(.blue)
                            Text(user.name).font(.system(size: 22, design: .monospaced))
                                .foregroundColor(.black)
                            Spacer()
                        }
                        .padding(5)
                        .background {
                            RoundedRectangle(cornerRadius: 10).fill(user.color)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    ContentView(document: .constant(CLIPSRunnerDocument()))
}
