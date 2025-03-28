// Copyright (c) 2025 David N Main

import CLIPSCore

/// A Fact Builder
public struct CLIPSFactBuilder: ~Copyable {

    /// Fact builder for a particular fact template.
    /// Set the slots tnen call ``assertFact()``.
    /// Multiple facts can be asserted, each requiring its own set
    /// of slots to be set.
    public struct Template: ~Copyable {
        let ptr: UnsafeMutablePointer<CLIPSCore.FactBuilder>
        let env: CLIPSEnvironment
        let pEnv: CLIPSEnvironment.Ptr

        /// Set a slot value.
        ///
        /// - Throws ``CLIPSPutSlotError``
        public func put(slot: String, value: CLIPSValue) throws(CLIPSPutSlotError) {
            var clipsValue = value.asCLIPSValue(pEnv: pEnv)
            let err = CLIPSCore.FBPutSlot(ptr, slot, &clipsValue)
            guard err == CLIPSCore.PSE_NO_ERROR else {
                throw CLIPSPutSlotError.from(err)
            }
        }

        /// Assert a fact with the slots values that have been set.
        /// Resets the slots values in preparation for building the
        /// next fact.
        ///
        /// - Returns: the newly asserted fact or the exising one
        /// - Throws: ``CLIPSFactBuilderError``
        public func assertFact() throws(CLIPSFactBuilderError) -> CLIPSFact {
            guard let fact = CLIPSCore.FBAssert(ptr) else {
                throw CLIPSFactBuilderError.from(CLIPSCore.FBError(pEnv))
            }

            return .init(ptr: fact, env: env)
        }
    }

    let pBuilder: UnsafeMutablePointer<CLIPSCore.FactBuilder>
    let env: CLIPSEnvironment
    let pEnv: CLIPSEnvironment.Ptr

    init(env: CLIPSEnvironment, pEnv: CLIPSEnvironment.Ptr) throws(CLIPSFactBuilderError) {
        guard let pBuilder = CLIPSCore.CreateFactBuilder(pEnv, nil) else {
            throw CLIPSFactBuilderError.from(CLIPSCore.FBError(pEnv))
        }
        self.env = env
        self.pEnv = pEnv
        self.pBuilder = pBuilder
    }

    deinit {
        // This will happen within the CLIPSEnvironment isolation so is OK
        CLIPSCore.FBDispose(pBuilder)
    }

    /// Use a closure to build facts using a particular template.
    ///
    /// - Parameter template: the name of the fact template to use
    /// - Throws: ``CLIPSFactBuilderError`` or ``CLIPSPutSlotError``
    ///
    public func using(template: String, _ body: (borrowing CLIPSFactBuilder.Template) throws -> Void) throws {
        let err = CLIPSCore.FBSetDeftemplate(pBuilder, template)
        guard err == CLIPSCore.FBE_NO_ERROR else {
            throw CLIPSFactBuilderError.from(err)
        }

        let pTemplateBuilder = CLIPSFactBuilder.Template(ptr: pBuilder, env: env, pEnv: pEnv)
        try body(pTemplateBuilder)
    }
}
