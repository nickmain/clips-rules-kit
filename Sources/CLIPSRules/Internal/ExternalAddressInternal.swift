// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation

// The discard function registered with the "swift" external address type
func discardFunction(_ env: CLIPS.EnvironmentPtr?,
                     _ addr: UnsafeMutableRawPointer?) -> Bool {
    guard let addr else { return false }

    // take a retained value in order to release it immediately
    _ = Unmanaged<AnyObject>.fromOpaque(addr).takeRetainedValue()

    return true
}
