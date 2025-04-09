// Copyright (c) 2025 David N Main

import CLIPSCore

/// A CLIPS fact.
///
/// The underlying fact is retained and released by this Swift instance.
///
public class CLIPSFact: Equatable {

    typealias Ptr = UnsafeMutablePointer<CLIPSCore.Fact>

    public static func == (lhs: CLIPSFact, rhs: CLIPSFact) -> Bool {
        lhs.ptr == rhs.ptr
    }

    let ptr: Ptr
    let env: CLIPSEnvironment

    public var template: CLIPSTemplate { .init(ptr: CLIPSCore.FactDeftemplate(ptr), env: env) }
    public var index: Int64 { ptr.pointee.factIndex }
    public var isAsserted: Bool { CLIPSCore.FactExistp(ptr) }

    init(ptr: Ptr, env: CLIPSEnvironment) {
        self.ptr = ptr
        self.env = env
        CLIPSCore.RetainFact(ptr)
    }

    deinit {
        Task { [ptr, env] in
            await env.withPtr { _ in
                CLIPSCore.ReleaseFact(ptr)
            }
        }
    }

    /// Get a pretty-print of the fact
    public func prettyPrint() async -> String {
        await env.withPtr { pEnv in
            guard let builder = CLIPSCore.CreateStringBuilder(pEnv, 100) else { return "<???>" }
            defer { CLIPSCore.SBDispose(builder) }

            CLIPSCore.FactPPForm(ptr, builder, false)
            return String(cString: builder.pointee.contents)
        }
    }

    public func getSlot(named name: String) async throws(CLIPSGetSlotError) -> CLIPSValue {
        try await env.withPtr { pEnv throws(CLIPSGetSlotError) in
            var value = CLIPSCore.CLIPSValue()
            let err = CLIPSCore.GetFactSlot(ptr, name, &value)
            guard err == CLIPSCore.GSE_NO_ERROR else {
                throw CLIPSGetSlotError.from(err)
            }

            return CLIPSValue.from(value: value, env: env, pEnv: pEnv)
        }
    }

    public func getNextFact() async -> CLIPSFact? {
        await env.withPtr { pEnv in
            guard let factPtr = CLIPSCore.GetNextFact(pEnv, ptr) else { return nil }
            return .init(ptr: factPtr, env: env)
        }
    }

    public func retract() async throws(CLIPSRetractError) {
        try await env.withPtr { _ throws(CLIPSRetractError) in
            let err = CLIPSCore.Retract(ptr)
            if err != CLIPSCore.RE_NO_ERROR {
                throw CLIPSRetractError.from(err)
            }
        }
    }
}
