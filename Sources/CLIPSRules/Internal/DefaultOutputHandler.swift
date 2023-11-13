// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation

// An output handler that writes to the defaultOutputLogger
class DefaultHandler: CLIPSOutputHandler {
    func handle(line: CLIPS.OutputLine) {
        switch line {
        case .stdout(line: let line): CLIPS.defaultOutputLogger.info("\(line)")
        case .error(line: let line): CLIPS.defaultOutputLogger.error("\(line)")
        case .warning(line: let line): CLIPS.defaultOutputLogger.warning("\(line)")
        case .named(name: let name, line: let line): CLIPS.defaultOutputLogger.info("\(name): \(line)")
        }
    }
}
