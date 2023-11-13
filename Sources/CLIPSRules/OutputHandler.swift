// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation

/// Handler for CLIPS output
public protocol CLIPSOutputHandler {

    /// Handle an output line.
    ///
    /// This will be called on the same thread as the CLIPS
    /// engine is running.
    func handle(line: CLIPS.OutputLine)
}

extension CLIPS {

    /// Types of CLIPS output
    public enum OutputLine {
        case stdout(line: String)
        case error(line: String)
        case warning(line: String)
        case named(name: String, line: String)

        static func from(name: String, line: String) -> OutputLine {
            if name == Router.stdout { return .stdout(line: line) }
            if name == Router.stderr { return .error(line: line) }
            if name == Router.stdwrn { return .warning(line: line) }
            return .named(name: name, line: line)
        }
    }
}
