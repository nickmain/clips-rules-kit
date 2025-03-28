// Copyright (c) 2025 David N Main

import Foundation

// The discard function registered with the "swift" external address type
func discardFunction(_ env: CLIPSEnvironment.Ptr?,
                     _ addr: UnsafeMutableRawPointer?) -> Bool {
    guard let addr else { return false }

    // take a retained value in order to release it immediately
    _ = Unmanaged<AnyObject>.fromOpaque(addr).takeRetainedValue()

    return true
}
