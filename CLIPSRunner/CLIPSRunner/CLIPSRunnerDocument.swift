// Copyright (c) 2024 David N Main

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var exampleText: UTType {
        UTType(importedAs: "com.example.plain-text")
    }
}

struct CLIPSRunnerDocument: FileDocument {

    class Content: Codable {
        var comment: String = ""
        var body: String = ""
    }

    var content = Content()

    init(text: String = "Hello, world!") {
        content.body = text
    }

    static var readableContentTypes: [UTType] { [.exampleText] }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }

        do {
            content = try JSONDecoder().decode(Content.self, from: data)
        } catch {
            content.comment = "Error reading \(configuration.file)"
            content.body = "JSON Decoding Error: \(error)"
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = try JSONEncoder().encode(content)
        return .init(regularFileWithContents: data)
    }
}
