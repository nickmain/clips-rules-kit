// Copyright (c) 2025 David N Main

import CLIPSCore

/// A CLIPS external address
///
/// The external address is retained and released by this Swift instance
///
public class CLIPSExternalAddress: Equatable {

    typealias Ptr = UnsafeMutablePointer<CLIPSCore.CLIPSExternalAddress>

    public static func == (lhs: CLIPSExternalAddress, rhs: CLIPSExternalAddress) -> Bool {
        lhs.ptr == rhs.ptr
    }

    let ptr: Ptr
    private let env: CLIPSEnvironment

    init(ptr: Ptr, env: CLIPSEnvironment) {
        self.ptr = ptr
        self.env = env

        // note that the env ptr is not used by CLIPS
        CLIPSCore.RetainExternalAddress(nil, ptr)
    }

    deinit {
        Task { [ptr, env] in
            await env.withPtr { pEnv in
                CLIPSCore.ReleaseExternalAddress(pEnv, ptr)
            }
        }
    }
}
