// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation
import CLIPSCore

extension CLIPS {

    typealias FactPtr = UnsafeMutablePointer<CLIPSCore.Fact>
    typealias FactTemplatePtr = UnsafeMutablePointer<CLIPSCore.Deftemplate>

    /// A CLIPS Fact
    public struct Fact: Equatable {
        internal let ptr: FactPtr
    }

    /// A fact template (DefTemplate construct)
    public struct FactTemplate: Equatable {
        internal let ptr: FactTemplatePtr
    }

    /// Scope for saving facts
    public enum SaveScope {
        /// Save only facts from templates defined in the current module
        case localToCurrentModule

        /// Save all facts visible to the current module
        case visibleToCurrentModule

        public var value: CLIPSCore.SaveScope {
            switch self {
            case .localToCurrentModule:   CLIPSCore.LOCAL_SAVE
            case .visibleToCurrentModule: CLIPSCore.VISIBLE_SAVE
            }
        }
    }

    /// A Fact Builder
    public struct FactBuilder {
        
        /// Fact builder for a particular fact template.
        /// Set the slots tnen call ``assertFact()``.
        /// Multiple facts can be asserted, each requiring its own set
        /// of slots to be set.
        public struct Template {
            let ptr: UnsafeMutablePointer<CLIPSCore.FactBuilder>
            let env: CLIPS.Environment

            /// Set a slot value.
            ///
            /// - Throws ``PutSlotError``
            public func put(slot: String, value: CLIPS.Value) throws {
                var clipsValue = value.asCLIPSValue(environment: env)
                let err = CLIPSCore.FBPutSlot(ptr, slot, &clipsValue)
                guard err == CLIPSCore.PSE_NO_ERROR else {
                    throw CLIPS.PutSlotError.from(err)
                }
            }

            /// Assert a fact with the slots values that have been set.
            /// Resets the slots values in preparation for building the
            /// next fact.
            ///
            /// - Returns: the newly asserted fact or the exising one
            /// - Throws: ``FactBuilderError``
            public func assertFact() throws -> CLIPS.Fact {
                guard let fact = CLIPSCore.FBAssert(ptr) else {
                    throw CLIPS.FactBuilderError.from(CLIPSCore.FBError(env.ptr))
                }

                return .init(ptr: fact)
            }
        }

        let ptr: UnsafeMutablePointer<CLIPSCore.FactBuilder>
        let env: CLIPS.Environment

        /// Use a closure to build facts using a particular template.
        ///
        /// - Parameter template: the name of the fact template to use
        /// - Throws: ``FactBuilderError``
        public func using(template: String, closure: (CLIPS.FactBuilder.Template) throws -> Void) throws {
            let err = CLIPSCore.FBSetDeftemplate(ptr, template)
            guard err == CLIPSCore.FBE_NO_ERROR else {
                throw CLIPS.FactBuilderError.from(err)
            }

            try closure(.init(ptr: ptr, env: env))
        }
    }
}

extension CLIPS.FactTemplate {
    /// The slot name for an ordered fact
    public static let IMPLIED_SLOT_NAME = "implied"
}

extension CLIPS.Environment {

    /// Use a closure to build and assert facts.
    ///
    /// - Throws: ``FactBuilderError`` or ``PutSlotError``
    public func buildFacts(closure: (CLIPS.FactBuilder) throws -> Void) throws {

        // create a fact builder without an initial template set
        guard let builder = CLIPSCore.CreateFactBuilder(ptr, nil) else {
            throw CLIPS.FactBuilderError.from(CLIPSCore.FBError(ptr))
        }
        defer {
            CLIPSCore.FBDispose(builder)
        }

        try closure(.init(ptr: builder, env: self))
    }

    /// Get the name of a template
    public func getName(of template: CLIPS.FactTemplate) -> String {
        String(cString: CLIPSCore.DeftemplateName(template.ptr))
    }

    /// Get the template for a fact
    public func getTemplate(for fact: CLIPS.Fact) -> CLIPS.FactTemplate {
        .init(ptr: CLIPSCore.FactDeftemplate(fact.ptr))
    }

    /// Get the slot names from the given fact template
    public func getSlotNames(for template: CLIPS.FactTemplate) -> [String] {
        var value = CLIPSCore.CLIPSValue()
        CLIPSCore.DeftemplateSlotNames(template.ptr, &value)
        let names = CLIPS.Value.from(value: value, environment: self)
        guard case let .multifield(nameArray) = names else {
            return []
        }

        return nameArray.compactMap { 
            if case let .symbol(name) = $0 { name } else { nil }
        }
    }

    /// Get a pretty-print of a Fact
    public func prettyPrint(fact: CLIPS.Fact) -> String {
        guard let builder = CLIPSCore.CreateStringBuilder(self.ptr, 100)
            else { return "<???>" }
        defer { CLIPSCore.SBDispose(builder) }

        CLIPSCore.FactPPForm(fact.ptr, builder, false)
        return String(cString: builder.pointee.contents)
    }

    /// Get the next fact after the given one.
    /// Pass a nil fact to get the first fact.
    ///
    /// - Parameter fact: must not be retracted
    /// - Returns: the next fact or nil if there are no more facts
    public func getNextFact(after fact: CLIPS.Fact?) -> CLIPS.Fact? {
        guard let factPtr = CLIPSCore.GetNextFact(ptr, fact?.ptr ?? nil) else { return nil }
        return .init(ptr: factPtr)
    }

    /// Get the next fact with the given template after the given fact.
    /// Pass a nil fact to get the first fact.
    ///
    /// - Parameter fact: must not be retracted
    /// - Returns: the next fact or nil if there are no more facts
    public func getNextFact(in template: CLIPS.FactTemplate, after fact: CLIPS.Fact?) -> CLIPS.Fact? {
        guard let ptr = CLIPSCore.GetNextFactInTemplate(template.ptr, fact?.ptr ?? nil) else { return nil }
        return .init(ptr: ptr)
    }

    /// Find a fact template by name
    public func findFactTemplate(named name: String) -> CLIPS.FactTemplate? {
        guard let ptr = CLIPSCore.FindDeftemplate(ptr, name) else { return nil }
        return .init(ptr: ptr)
    }

    /// Get the value of a fact slot.
    ///
    /// - Returns: the slot value
    /// - Throws: ``GetSlotError``
    public func getSlot(of fact: CLIPS.Fact, named name: String) throws -> CLIPS.Value {
        var value = CLIPSCore.CLIPSValue()
        let err = CLIPSCore.GetFactSlot(fact.ptr, name, &value)
        guard err == CLIPSCore.GSE_NO_ERROR else {
            throw CLIPS.GetSlotError.from(err)
        }

        return CLIPS.Value.from(value: value, environment: self)
    }

    /// Assert a fact from a string.
    ///
    /// - Returns: a pointer to the asserted fact
    /// - Throws: ``AssertStringError``
    @discardableResult
    public func assert(fact: String) throws -> CLIPS.Fact {
        guard let factPtr = CLIPSCore.AssertString(ptr, fact) else {
            let err = CLIPSCore.GetAssertStringError(ptr)
            throw CLIPS.AssertStringError(kind: err, fact: fact)
        }

        return .init(ptr: factPtr)
    }

    /// Whether the fact exists. 
    /// The fact must either be asserted or retained, it cannot have been
    /// garbage collected.
    ///
    /// - Returns: false if the fact has been retracted.
    public func factExists(_ fact: CLIPS.Fact) -> Bool {
        CLIPSCore.FactExistp(fact.ptr)
    }

    /// Retain a fact so that it is not deleted when retracted
    public func retain(fact: CLIPS.Fact) {
        CLIPSCore.RetainFact(fact.ptr)
    }

    /// Release a previously retained fact
    public func release(fact: CLIPS.Fact) {
        CLIPSCore.ReleaseFact(fact.ptr)
    }

    /// Retract a fact.
    ///
    /// - Parameter fact: the fact to retract
    /// - Throws: ``RetractError``
    public func retract(fact: CLIPS.Fact) throws {
        let err = CLIPSCore.Retract(fact.ptr)
        if err != CLIPSCore.RE_NO_ERROR {
            throw CLIPS.RetractError.from(err)
        }
    }

    /// Retract all facts.
    ///
    /// - Throws: ``RetractError``
    public func retractAllFacts() throws {
        let err = CLIPSCore.RetractAllFacts(ptr)
        if err != CLIPSCore.RE_NO_ERROR {
            throw CLIPS.RetractError.from(err)
        }
    }

    /// Whether the set of facts have changed since this value was set to false
    public var factListChanged: Bool {
        get { CLIPSCore.GetFactListChanged(ptr) }
        set { CLIPSCore.SetFactListChanged(ptr, newValue) }
    }

    /// Whether duplicate facts are allowed - initially false.
    public var duplicateFactsAllowed: Bool {
        get { CLIPSCore.GetFactDuplication(ptr) }
        set { CLIPSCore.SetFactDuplication(ptr, newValue) }
    }

    /// Load facts from a text file
    ///
    /// - Returns: number of facts loaded or -1 of there was an error
    public func loadFacts(from filename: String) -> Int {
        CLIPSCore.LoadFacts(ptr, filename)
    }

    /// Save facts in the given scope to a text file
    ///
    /// - Returns: count of facts saved or -1 of there was an error
    public func saveFacts(to filename: String, scope: CLIPS.SaveScope) -> Int {
        CLIPSCore.SaveFacts(ptr, filename, scope.value)
    }

    /// Load facts from a binary file
    ///
    /// - Returns: number of facts loaded or -1 of there was an error
    public func loadBinaryFacts(from filename: String) -> Int {
        CLIPSCore.BinaryLoadFacts(ptr, filename)
    }

    /// Save facts in the given scope to a binary file
    ///
    /// - Returns: count of facts saved or -1 of there was an error
    public func saveBinaryFacts(to filename: String, scope: CLIPS.SaveScope) -> Int {
        CLIPSCore.BinarySaveFacts(ptr, filename, scope.value)
    }

    /// Load facts from a string
    ///
    /// - Returns: number of facts loaded or -1 of there was an error
    public func loadFacts(fromString string: String) -> Int {
        CLIPSCore.LoadFactsFromString(ptr, string, Int.max)
    }

    /// A fact and a dictionary of its slot values
    public struct FactAndSlots: Equatable {
        public let templateName: String
        public let slots: [String: CLIPS.Value]
    }

    /// Get all facts and their slot values, keyed by template name
    public func getAllFacts() -> [FactAndSlots] {
        var facts = [FactAndSlots]()

        var fact: CLIPS.Fact?
        while true {
            fact = self.getNextFact(after: fact)
            guard let fact else { break }

            let template = getTemplate(for: fact)
            let templateName = getName(of: template)
            let slotNames = getSlotNames(for: template)
            var slotValues = [String: CLIPS.Value]()
            for slotName in slotNames {
                slotValues[slotName] = try! getSlot(of: fact, named: slotName)
            }
            facts.append(.init(templateName: templateName, slots: slotValues))
        }

        return facts
    }
}
