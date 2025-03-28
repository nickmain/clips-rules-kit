// Copyright (c) 2025 David N Main

import Foundation

// An output handler that writes to the defaultOutputLogger
class CLIPSDefaultHandler: CLIPSOutputHandler {
    func handle(line: CLIPSOutputLine) {
        switch line {
        case .stdout(line: let line): CLIPSEnvironment.defaultOutputLogger.info("\(line)")
        case .error(line: let line): CLIPSEnvironment.defaultOutputLogger.error("\(line)")
        case .warning(line: let line): CLIPSEnvironment.defaultOutputLogger.warning("\(line)")
        case .named(name: let name, line: let line): CLIPSEnvironment.defaultOutputLogger.info("\(name): \(line)")
        }
    }
}
