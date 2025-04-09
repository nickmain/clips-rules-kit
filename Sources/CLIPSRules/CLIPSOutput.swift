// Copyright (c) 2025 David N Main

import Foundation

/// Handler for CLIPS output
public protocol CLIPSOutputHandler {

    /// Handle an output line.
    ///
    /// This will be called on the same thread as the CLIPS
    /// engine is running.
    func handle(line: CLIPSOutputLine)
}

/// Types of CLIPS output
public enum CLIPSOutputLine {
    case stdout(line: String)
    case error(line: String)
    case warning(line: String)
    case named(name: String, line: String)

    static func from(name: String, line: String) -> CLIPSOutputLine {
        if name == CLIPSRouter.stdout { return .stdout(line: line) }
        if name == CLIPSRouter.stderr { return .error(line: line) }
        if name == CLIPSRouter.stdwrn { return .warning(line: line) }
        return .named(name: name, line: line)
    }
}
