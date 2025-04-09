// Copyright (c) 2025 David N Main

import Foundation
import CLIPSCore

public struct CLIPSModule {

    typealias Ptr = UnsafeMutablePointer<CLIPSCore.Defmodule>

    let ptr: Ptr
    let env: CLIPSEnvironment

    public var name: String { String(cString: CLIPSCore.DefmoduleName(ptr)) }
    public var prettyPrint: String {
        guard let pChar = CLIPSCore.DefmodulePPForm(ptr) else { return "module \(name)" }
        return String(cString: pChar)
    }

    init(ptr: Ptr, env: CLIPSEnvironment) {
        self.ptr = ptr
        self.env = env
    }

    /// Make this the current module and return the previous current module
    @discardableResult
    public func setAsCurrent() async -> CLIPSModule {
        await env.withPtr { pEnv in
            .init(ptr: CLIPSCore.SetCurrentModule(pEnv, ptr), env: env)
        }
    }

    public func getNextModule() async -> CLIPSModule? {
        await env.withPtr { pEnv in
            guard let pModule = CLIPSCore.GetNextDefmodule(pEnv, ptr) else { return nil }
            return .init(ptr: pModule, env: env)
        }
    }
}
