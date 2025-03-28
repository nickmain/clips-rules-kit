// Copyright (c) 2025 David N Main

import CLIPSCore

/// A CLIPS Instance.
///
/// The underlying instance is retained and released by this Swift instance.
///
public class CLIPSInstance: Equatable {

    typealias Ptr = UnsafeMutablePointer<CLIPSCore.Instance>

    public static func == (lhs: CLIPSInstance, rhs: CLIPSInstance) -> Bool {
        lhs.ptr == rhs.ptr
    }

    let ptr: Ptr
    private let env: CLIPSEnvironment

    public var name: String { String(cString: CLIPSCore.InstanceName(ptr)) }
    public var clipsClass: CLIPSClass { CLIPSClass(ptr: CLIPSCore.InstanceClass(ptr), env: env) }
    public var isValid: Bool { CLIPSCore.ValidInstanceAddress(ptr) }

    init(ptr: Ptr, env: CLIPSEnvironment) {
        self.ptr = ptr
        self.env = env
        CLIPSCore.RetainInstance(ptr)
    }

    deinit {
        Task { [ptr, env] in
            await env.withPtr { _ in
                CLIPSCore.ReleaseInstance(ptr)
            }
        }
    }

    /// Unmake the instance.
    ///
    /// - Throws: ``CLIPSUnmakeInstanceError``
    ///
    public func unmake() async throws(CLIPSUnmakeInstanceError) {
        try await env.withPtr { _ throws(CLIPSUnmakeInstanceError) in
            let err = CLIPSCore.UnmakeInstance(ptr)
            if err != CLIPSCore.UIE_NO_ERROR {
                throw CLIPSUnmakeInstanceError.from(err)
            }
        }
    }

    /// Delete the instance, bypassing message passing.
    ///
    /// - Throws: ``CLIPSUnmakeInstanceError``
    ///
    public func delete() async throws(CLIPSUnmakeInstanceError) {
        try await env.withPtr { _ throws(CLIPSUnmakeInstanceError) in
            let err = CLIPSCore.DeleteInstance(ptr)
            if err != CLIPSCore.UIE_NO_ERROR {
                throw CLIPSUnmakeInstanceError.from(err)
            }
        }
    }

    /// Get a pretty-print of the instance
    public func prettyPrint() async -> String {
        await env.withPtr { pEnv in
            guard let builder = CLIPSCore.CreateStringBuilder(pEnv, 100) else { return "<???>" }
            defer { CLIPSCore.SBDispose(builder) }

            CLIPSCore.InstancePPForm(ptr, builder)
            return String(cString: builder.pointee.contents)
        }
    }

    public func getNextInstance() async -> CLIPSInstance? {
        await env.withPtr { pEnv in
            guard let nextPtr = CLIPSCore.GetNextInstance(pEnv, ptr) else { return nil }
            return CLIPSInstance(ptr: nextPtr, env: env)
        }
    }

    /// Get the value of an instance slot (bypassing message handling).
    ///
    /// - Returns: the slot value
    /// - Throws: ``CLIPSGetSlotError``
    ///
    public func directGetSlot(named name: String) async throws(CLIPSGetSlotError) -> CLIPSValue {
        try await env.withPtr { pEnv throws(CLIPSGetSlotError) in
            var value = CLIPSCore.CLIPSValue()
            let err = CLIPSCore.DirectGetSlot(ptr, name, &value)
            guard err == CLIPSCore.GSE_NO_ERROR else {
                throw CLIPSGetSlotError.from(err)
            }

            return CLIPSValue.from(value: value, env: env, pEnv: pEnv)
        }
    }

    /// Set the value of an instance slot (bypassing message handling).
    ///
    /// - Throws: ``CLIPSPutSlotError``
    ///
    public func directSetSlot(named name: String, to value: CLIPSValue) async throws {
        try await env.withPtr { pEnv throws(CLIPSPutSlotError) in
            var val = value.asCLIPSValue(pEnv: pEnv)
            let err = CLIPSCore.DirectPutSlot(ptr, name, &val)
            guard err == CLIPSCore.PSE_NO_ERROR else {
                throw CLIPSPutSlotError.from(err)
            }
        }
    }

    public func setSlots(_ body: (borrowing SlotSetter) throws(CLIPSPutSlotError) -> Void) async throws(CLIPSPutSlotError) {
        try await env.withPtr { pEnv throws(CLIPSPutSlotError) in
            try body(.init(ptr: ptr))
        }
    }

    public struct SlotSetter: ~Copyable {
        let ptr: CLIPSInstance.Ptr

        /// Set the value of an instance slot (bypassing message handling).
        ///
        /// - Throws: ``CLIPSPutSlotError``
        ///
        public func directSetSlot(named name: String, to value: Int) throws(CLIPSPutSlotError) {
            let err = CLIPSCore.DirectPutSlotInteger(ptr, name, Int64(value))
            guard err == CLIPSCore.PSE_NO_ERROR else {
                throw CLIPSPutSlotError.from(err)
            }
        }

        /// Set the value of an instance slot (bypassing message handling).
        ///
        /// - Throws: ``CLIPSPutSlotError``
        ///
        public func directSetSlot(named name: String, to value: Double) throws(CLIPSPutSlotError) {
            let err = CLIPSCore.DirectPutSlotFloat(ptr, name, value)
            guard err == CLIPSCore.PSE_NO_ERROR else {
                throw CLIPSPutSlotError.from(err)
            }
        }

        /// Set the value of an instance slot (bypassing message handling).
        ///
        /// - Throws: ``CLIPSPutSlotError``
        ///
        public func directSetSlot(named name: String, toString value: String) throws(CLIPSPutSlotError) {
            let err = CLIPSCore.DirectPutSlotString(ptr, name, value)
            guard err == CLIPSCore.PSE_NO_ERROR else {
                throw CLIPSPutSlotError.from(err)
            }
        }

        /// Set the value of an instance slot (bypassing message handling).
        ///
        /// - Throws: ``CLIPSPutSlotError``
        ///
        public func directSetSlot(named name: String, toSymbol value: String) throws(CLIPSPutSlotError) {
            let err = CLIPSCore.DirectPutSlotSymbol(ptr, name, value)
            guard err == CLIPSCore.PSE_NO_ERROR else {
                throw CLIPSPutSlotError.from(err)
            }
        }

        /// Set the value of an instance slot (bypassing message handling).
        ///
        /// - Throws: ``CLIPSPutSlotError``
        ///
        public func directSetSlot(named name: String, toInstanceName value: String) throws(CLIPSPutSlotError) {
            let err = CLIPSCore.DirectPutSlotInstanceName(ptr, name, value)
            guard err == CLIPSCore.PSE_NO_ERROR else {
                throw CLIPSPutSlotError.from(err)
            }
        }

        /// Set the value of an instance slot (bypassing message handling).
        ///
        /// - Throws: ``CLIPSPutSlotError``
        ///
        public func directSetSlot(named name: String, toFact value: CLIPSFact) throws(CLIPSPutSlotError) {
            let err = CLIPSCore.DirectPutSlotFact(ptr, name, value.ptr)
            guard err == CLIPSCore.PSE_NO_ERROR else {
                throw CLIPSPutSlotError.from(err)
            }
        }

        /// Set the value of an instance slot (bypassing message handling).
        ///
        /// - Throws: ``CLIPSPutSlotError``
        ///
        public func directSetSlot(named name: String, toInstance value: CLIPSInstance) throws(CLIPSPutSlotError) {
            let err = CLIPSCore.DirectPutSlotInstance(ptr, name, value.ptr)
            guard err == CLIPSCore.PSE_NO_ERROR else {
                throw CLIPSPutSlotError.from(err)
            }
        }

        /// Set the value of an instance slot (bypassing message handling).
        ///
        /// - Throws: ``CLIPSPutSlotError``
        ///
        public func directSetSlot(named name: String, toExternalAddress value: CLIPSExternalAddress) throws(CLIPSPutSlotError) {
            let err = CLIPSCore.DirectPutSlotCLIPSExternalAddress(ptr, name, value.ptr)
            guard err == CLIPSCore.PSE_NO_ERROR else {
                throw CLIPSPutSlotError.from(err)
            }
        }
    }
}
