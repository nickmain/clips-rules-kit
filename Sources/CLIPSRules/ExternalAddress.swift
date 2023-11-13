// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation
import CLIPSCore

extension CLIPS {

    /// A CLIPS External Address
    public struct ExternalAddress: Equatable {
        internal let ptr: ExternalAddressPtr
    }
}

extension CLIPS.Environment {

    /// Create an external address pointing at the given object.
    /// The address is unretained and will be garbage collected unless
    /// retained before the next gc trigger (such as a call to eval).
    /// The object is Swift-retained by the external address and will be
    /// Swift-released when the address is garbage collected.
    public func createExternalAddress(_ object: AnyObject) -> CLIPS.ExternalAddress {
        // pass a retained value so that the external address owns a reference
        // count on the object
        let objectPtr = UnsafeMutableRawPointer(Unmanaged.passRetained(object).toOpaque())

        return .init(ptr: CLIPSCore.CreateExternalAddress(self.ptr, objectPtr, UInt16(extAddrTypeCode)))
    }

    /// Get the object from an external address that was created by the
    /// ``CLIPS/Environment/createExternalAddress(_:)`` method.
    public func object(from externalAddress: CLIPS.ExternalAddress) -> AnyObject? {
        guard externalAddress.ptr.pointee.type == extAddrTypeCode else { return nil }

        guard let ptr = externalAddress.ptr.pointee.contents else { return nil }

        // Take an unretained value so that the swift reference count
        // is incremented
        return Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue()
    }

    /// Retain an external address
    public func retain(_ addr: CLIPS.ExternalAddress) {
        CLIPSCore.RetainExternalAddress(ptr, addr.ptr)
    }

    /// Release an external address
    public func release(_ addr: CLIPS.ExternalAddress) {
        CLIPSCore.ReleaseExternalAddress(ptr, addr.ptr)
    }
}
