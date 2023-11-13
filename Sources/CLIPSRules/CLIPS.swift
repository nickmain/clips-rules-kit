// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation
import OSLog
import CLIPSCore

/// The CLIPS namespace
public struct CLIPS {

    /// The Logger to use for debug and warning messages
    public static var logger = Logger(subsystem: "CLIPS", category: "DEBUG")

    /// The Logger to use for default output
    public static var defaultOutputLogger = Logger(subsystem: "CLIPS", category: "DefaultOutput")

    // prevent instantiation
    private init() {}
}
