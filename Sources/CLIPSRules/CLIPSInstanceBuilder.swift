// Copyright (c) 2025 David N Main

import CLIPSCore

/// An Instance builder
public struct CLIPSInstanceBuilder: ~Copyable {

    /// Instance builder for a particular class.
    /// Set the slots tnen call `makeInstance()``.
    /// Multiple instances can be created, each requiring its own set
    /// of slots to be set.
    public struct ClassDef: ~Copyable {
        let pBuilder: UnsafeMutablePointer<CLIPSCore.InstanceBuilder>
        let env: CLIPSEnvironment
        let pEnv: CLIPSEnvironment.Ptr

        /// Set a slot value.
        ///
        /// - Throws ``CLIPSPutSlotError``
        public func put(slot name: String, value: CLIPSValue) throws(CLIPSPutSlotError) {
            var clipsValue = value.asCLIPSValue(pEnv: pEnv)
            let err = CLIPSCore.IBPutSlot(pBuilder, name, &clipsValue)
            guard err == CLIPSCore.PSE_NO_ERROR else {
                throw CLIPSPutSlotError.from(err)
            }
        }

        /// Create an instance with the slots values that have been set.
        /// Resets the slots values in preparation for building the
        /// next instance.
        ///
        /// - Parameter name: the name for the new instance, nil to auto-generate a name
        /// - Returns: the new instance
        /// - Throws: ``CLIPSInstanceBuilderError``
        public func makeInstance(named name: String? = nil) throws -> CLIPSInstance {
            guard let instance = CLIPSCore.IBMake(pBuilder, name) else {
                throw CLIPSInstanceBuilderError.from(CLIPSCore.IBError(pEnv))
            }

            return .init(ptr: instance, env: env)
        }
    }

    let pBuilder: UnsafeMutablePointer<CLIPSCore.InstanceBuilder>
    let env: CLIPSEnvironment
    let pEnv: CLIPSEnvironment.Ptr

    init(env: CLIPSEnvironment, pEnv: CLIPSEnvironment.Ptr) throws {
        guard let pBuilder = CLIPSCore.CreateInstanceBuilder(pEnv, nil) else {
            throw CLIPSInstanceBuilderError.from(CLIPSCore.IBError(pEnv))
        }
        self.env = env
        self.pEnv = pEnv
        self.pBuilder = pBuilder
    }

    deinit {
        // OK because runs in CLIPEnvironment isolation
        CLIPSCore.IBDispose(pBuilder)
    }

    /// Use a closure to build instances of a particular class.
    ///
    /// - Parameter className: the name of the class
    /// - Throws: ``CLIPSInstanceBuilderError``
    ///
    public func using(className: String, _ body: (borrowing CLIPSInstanceBuilder.ClassDef) throws -> Void) throws {
        let err = CLIPSCore.IBSetDefclass(pBuilder, className)
        guard err == CLIPSCore.IBE_NO_ERROR else {
            throw CLIPSInstanceBuilderError.from(err)
        }

        let classBuilder = ClassDef(pBuilder: pBuilder, env: env, pEnv: pEnv)
        try body(classBuilder)
    }
}
