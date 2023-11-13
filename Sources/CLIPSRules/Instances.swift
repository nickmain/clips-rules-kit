// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation
import CLIPSCore

extension CLIPS {

    typealias InstancePtr = UnsafeMutablePointer<CLIPSCore.Instance>
    typealias ClassDefPtr = UnsafeMutablePointer<CLIPSCore.Defclass>

    /// A CLIPS Class Definition
    public struct ClassDefinition: Equatable {
        internal let ptr: ClassDefPtr
    }

    /// A CLIPS Instance
    public struct Instance: Equatable {
        internal let ptr: InstancePtr
    }

    /// An Instance builder
    public struct InstanceBuilder {

        /// Instance builder for a particular class.
        /// Set the slots tnen call `makeInstance()``.
        /// Multiple instances can be created, each requiring its own set
        /// of slots to be set.
        public struct ClassDef {
            let ptr: UnsafeMutablePointer<CLIPSCore.InstanceBuilder>
            let env: CLIPS.Environment

            /// Set a slot value.
            ///
            /// - Throws ``PutSlotError``
            public func put(slot: String, value: CLIPS.Value) throws {
                var clipsValue = value.asCLIPSValue(environment: env)
                let err = CLIPSCore.IBPutSlot(ptr, slot, &clipsValue)
                guard err == CLIPSCore.PSE_NO_ERROR else {
                    throw CLIPS.PutSlotError.from(err)
                }
            }

            /// Create an instance with the slots values that have been set.
            /// Resets the slots values in preparation for building the
            /// next instance.
            ///
            /// - Parameter name: the name for the new instance, nil to auto-generate a name
            /// - Returns: the new instance
            /// - Throws: ``InstanceBuilderError``
            public func makeInstance(named name: String? = nil) throws -> CLIPS.Instance {

                guard let instance = CLIPSCore.IBMake(ptr, name) else {
                    throw CLIPS.InstanceBuilderError.from(CLIPSCore.IBError(env.ptr))
                }

                return .init(ptr: instance)
            }
        }

        let ptr: UnsafeMutablePointer<CLIPSCore.InstanceBuilder>
        let env: CLIPS.Environment

        /// Use a closure to build instances of a particular class.
        ///
        /// - Parameter className: the name of the class
        /// - Throws: ``InstanceBuilderError``
        public func using(className: String, closure: (CLIPS.InstanceBuilder.ClassDef) throws -> Void) throws {
            let err = CLIPSCore.IBSetDefclass(ptr, className)
            guard err == CLIPSCore.IBE_NO_ERROR else {
                throw CLIPS.InstanceBuilderError.from(err)
            }

            try closure(.init(ptr: ptr, env: env))
        }
    }
}

extension CLIPS.Environment {
    
    /// Use a closure to build instances.
    ///
    /// - Throws: ``InstanceBuilderError`` or ``PutSlotError``
    public func buildInstances(closure: (CLIPS.InstanceBuilder) throws -> Void) throws {

        // create a builder without an initial class set up
        guard let builder = CLIPSCore.CreateInstanceBuilder(ptr, nil) else {
            throw CLIPS.InstanceBuilderError.from(CLIPSCore.IBError(ptr))
        }
        defer {
            CLIPSCore.IBDispose(builder)
        }

        try closure(.init(ptr: builder, env: self))
    }

    /// Get the class of an instance
    public func getClass(of instance: CLIPS.Instance) -> CLIPS.ClassDefinition {
        .init(ptr: CLIPSCore.InstanceClass(instance.ptr))
    }

    /// Get the module name of a class
    public func getModuleName(of classDef: CLIPS.ClassDefinition) -> String {
        String(cString: CLIPSCore.DefclassModule(classDef.ptr))
    }

    /// Get the name of a class
    public func getName(of classDef: CLIPS.ClassDefinition) -> String {
        String(cString: CLIPSCore.DefclassName(classDef.ptr))
    }

    /// Get name of an instance
    public func getName(of instance: CLIPS.Instance) -> String {
        String(cString: CLIPSCore.InstanceName(instance.ptr))
    }

    /// Get the slot names from the given class definition, with or without inherited slots
    public func getSlotNames(for classDef: CLIPS.ClassDefinition, inherit: Bool) -> [String] {
        var value = CLIPSCore.CLIPSValue()
        CLIPSCore.ClassSlots(classDef.ptr, &value, inherit)
        let names = CLIPS.Value.from(value: value, environment: self)
        guard case let .multifield(nameArray) = names else {
            return []
        }

        return nameArray.compactMap {
            if case let .symbol(name) = $0 { name } else { nil }
        }
    }

    /// Find an instance by name.
    ///
    /// - Parameters:
    ///   - name: the instance name to find
    ///   - module: the module to search, nil (default) for current module
    ///   - searchImports: whether to also search the module imports, default false
    /// - Returns: the instance or nil if not found
    ///
    public func findInstance(named name: String, in module: CLIPS.Module? = nil, searchImports: Bool = false) -> CLIPS.Instance? {
        if let ptr = CLIPSCore.FindInstance(self.ptr, module?.ptr, name, searchImports) {
            .init(ptr: ptr)
        } else {
            nil
        }
    }

    /// Get a pretty-print of an Instance
    public func prettyPrint(instance: CLIPS.Instance) -> String {
        guard let builder = CLIPSCore.CreateStringBuilder(self.ptr, 100)
            else { return "<???>" }
        defer { CLIPSCore.SBDispose(builder) }

        CLIPSCore.InstancePPForm(instance.ptr, builder)
        return String(cString: builder.pointee.contents)
    }

    /// Retain an instance
    public func retain(instance: CLIPS.Instance) {
        CLIPSCore.RetainInstance(instance.ptr)
    }

    /// Release a previously retained instance
    public func release(instance: CLIPS.Instance) {
        CLIPSCore.ReleaseInstance(instance.ptr)
    }

    /// Create an instance from a string.
    ///
    /// - Returns: a pointer to the instance
    /// - Throws: ``MakeInstanceError``
    @discardableResult
    public func make(instance: String) throws -> CLIPS.Instance {
        guard let instPtr = CLIPSCore.MakeInstance(ptr, instance) else {
            let err = CLIPSCore.GetMakeInstanceError(ptr)
            throw CLIPS.MakeInstanceError(kind: err, instance: instance)
        }

        return .init(ptr: instPtr)
    }

    /// Unmake an instance.
    ///
    /// - Parameter instance: the instance to unmake
    /// - Throws: ``UnmakeInstanceError``
    public func unmake(instance: CLIPS.Instance) throws {
        let err = CLIPSCore.UnmakeInstance(instance.ptr)
        if err != CLIPSCore.UIE_NO_ERROR {
            throw CLIPS.UnmakeInstanceError.from(err)
        }
    }

    /// Delete an instance, bypassing message passing.
    ///
    /// - Parameter instance: the instance to delete
    /// - Throws: ``UnmakeInstanceError``
    public func delete(instance: CLIPS.Instance) throws {
        let err = CLIPSCore.DeleteInstance(instance.ptr)
        if err != CLIPSCore.UIE_NO_ERROR {
            throw CLIPS.UnmakeInstanceError.from(err)
        }
    }

    /// Check whether an instance is still valid. The instance must not have been
    /// deleted or must have been retained.
    ///
    /// - Parameter instance: the instance to check
    public func isValid(instance: CLIPS.Instance) -> Bool {
        CLIPSCore.ValidInstanceAddress(instance.ptr)
    }

    /// Whether the set of instances and instance values has changed since this value was set to false
    public var instancesChanged: Bool {
        get { CLIPSCore.GetInstancesChanged(ptr) }
        set { CLIPSCore.SetInstancesChanged(ptr, newValue) }
    }

    /// Load instances from a text file
    ///
    /// - Returns: number of instances loaded or -1 of there was an error
    public func loadInstances(from filename: String) -> Int {
        CLIPSCore.LoadInstances(ptr, filename)
    }

    /// Save instances in the given scope to a text file
    ///
    /// - Returns: count of instances saved or -1 of there was an error
    public func saveInstances(to filename: String, scope: CLIPS.SaveScope) -> Int {
        CLIPSCore.SaveInstances(ptr, filename, scope.value)
    }

    /// Load instances from a binary file
    ///
    /// - Returns: number of instances loaded or -1 of there was an error
    public func loadBinaryInstances(from filename: String) -> Int {
        CLIPSCore.BinaryLoadInstances(ptr, filename)
    }

    /// Save instances in the given scope to a binary file
    ///
    /// - Returns: count of instances saved or -1 of there was an error
    public func saveBinaryInstances(to filename: String, scope: CLIPS.SaveScope) -> Int {
        CLIPSCore.BinarySaveInstances(ptr, filename, scope.value)
    }

    /// Load instances from a string
    ///
    /// - Returns: number of instances loaded or -1 of there was an error
    public func loadInstances(fromString string: String) -> Int {
        CLIPSCore.LoadInstancesFromString(ptr, string, Int.max)
    }

    /// Restore instances from a text file. Bypasses message handling.
    ///
    /// - Returns: number of instances loaded or -1 of there was an error
    public func restoreInstances(from filename: String) -> Int {
        CLIPSCore.RestoreInstances(ptr, filename)
    }

    /// Restore instances from a string, Bypasses message handling.
    ///
    /// - Returns: number of instances loaded or -1 of there was an error
    public func restoreInstances(fromString string: String) -> Int {
        CLIPSCore.RestoreInstancesFromString(ptr, string, Int.max)
    }

    /// Get the value of an instance slot (bypassing message handling).
    ///
    /// - Returns: the slot value
    /// - Throws: ``GetSlotError``
    public func directGetSlot(of instance: CLIPS.Instance, named name: String) throws -> CLIPS.Value {
        var value = CLIPSCore.CLIPSValue()
        let err = CLIPSCore.DirectGetSlot(instance.ptr, name, &value)
        guard err == CLIPSCore.GSE_NO_ERROR else {
            throw CLIPS.GetSlotError.from(err)
        }

        return CLIPS.Value.from(value: value, environment: self)
    }

    /// Set the value of an instance slot (bypassing message handling).
    ///
    /// - Throws: ``PutSlotError``
    public func directSetSlot(of instance: CLIPS.Instance, named name: String, to value: CLIPS.Value) throws {
        var val = value.asCLIPSValue(environment: self)
        let err = CLIPSCore.DirectPutSlot(instance.ptr, name, &val)
        guard err == CLIPSCore.PSE_NO_ERROR else {
            throw CLIPS.PutSlotError.from(err)
        }
    }

    /// Set the value of an instance slot (bypassing message handling).
    ///
    /// - Throws: ``PutSlotError``
    public func directSetSlot(of instance: CLIPS.Instance, named name: String, to value: Int) throws {
        let err = CLIPSCore.DirectPutSlotInteger(instance.ptr, name, Int64(value))
        guard err == CLIPSCore.PSE_NO_ERROR else {
            throw CLIPS.PutSlotError.from(err)
        }
    }

    /// Set the value of an instance slot (bypassing message handling).
    ///
    /// - Throws: ``PutSlotError``
    public func directSetSlot(of instance: CLIPS.Instance, named name: String, to value: Double) throws {
        let err = CLIPSCore.DirectPutSlotFloat(instance.ptr, name, value)
        guard err == CLIPSCore.PSE_NO_ERROR else {
            throw CLIPS.PutSlotError.from(err)
        }
    }

    /// Set the value of an instance slot (bypassing message handling).
    ///
    /// - Throws: ``PutSlotError``
    public func directSetSlot(of instance: CLIPS.Instance, named name: String, toString value: String) throws {
        let err = CLIPSCore.DirectPutSlotString(instance.ptr, name, value)
        guard err == CLIPSCore.PSE_NO_ERROR else {
            throw CLIPS.PutSlotError.from(err)
        }
    }

    /// Set the value of an instance slot (bypassing message handling).
    ///
    /// - Throws: ``PutSlotError``
    public func directSetSlot(of instance: CLIPS.Instance, named name: String, toSymbol value: String) throws {
        let err = CLIPSCore.DirectPutSlotSymbol(instance.ptr, name, value)
        guard err == CLIPSCore.PSE_NO_ERROR else {
            throw CLIPS.PutSlotError.from(err)
        }
    }   

    /// Set the value of an instance slot (bypassing message handling).
    ///
    /// - Throws: ``PutSlotError``
    public func directSetSlot(of instance: CLIPS.Instance, named name: String, toInstanceName value: String) throws {
        let err = CLIPSCore.DirectPutSlotInstanceName(instance.ptr, name, value)
        guard err == CLIPSCore.PSE_NO_ERROR else {
            throw CLIPS.PutSlotError.from(err)
        }
    }

    /// Set the value of an instance slot (bypassing message handling).
    ///
    /// - Throws: ``PutSlotError``
    public func directSetSlot(of instance: CLIPS.Instance, named name: String, toFact value: CLIPS.Fact) throws {
        let err = CLIPSCore.DirectPutSlotFact(instance.ptr, name, value.ptr)
        guard err == CLIPSCore.PSE_NO_ERROR else {
            throw CLIPS.PutSlotError.from(err)
        }
    }

    /// Set the value of an instance slot (bypassing message handling).
    ///
    /// - Throws: ``PutSlotError``
    public func directSetSlot(of instance: CLIPS.Instance, named name: String, toInstance value: CLIPS.Instance) throws {
        let err = CLIPSCore.DirectPutSlotInstance(instance.ptr, name, value.ptr)
        guard err == CLIPSCore.PSE_NO_ERROR else {
            throw CLIPS.PutSlotError.from(err)
        }
    }

    /// Set the value of an instance slot (bypassing message handling).
    ///
    /// - Throws: ``PutSlotError``
    public func directSetSlot(of instance: CLIPS.Instance, named name: String, toExternalAddress value: CLIPS.ExternalAddress) throws {
        let err = CLIPSCore.DirectPutSlotCLIPSExternalAddress(instance.ptr, name, value.ptr)
        guard err == CLIPSCore.PSE_NO_ERROR else {
            throw CLIPS.PutSlotError.from(err)
        }
    }

    /// Get the next instance after the given one.
    /// Pass a nil instance to get the first instance.
    ///
    /// - Parameters:
    ///   - instance: default nil
    /// - Returns: the next instance or nil if there are no more
    public func getNextInstance(after instance: CLIPS.Instance? = nil) -> CLIPS.Instance? {
        guard let instancePtr = CLIPSCore.GetNextInstance(ptr, instance?.ptr) else { return nil }
        return .init(ptr: instancePtr)
    }

    /// Get the next instance after the given one, for the given class.
    /// Pass a nil instance to get the first instance.
    ///
    /// - Parameters:
    ///   - classDef: class for instances
    ///   - instance: default nil
    /// - Returns: the next instance or nil if there are no more
    public func getNextInstance(for classDef: CLIPS.ClassDefinition, after instance: CLIPS.Instance? = nil) -> CLIPS.Instance? {
        guard let instancePtr = CLIPSCore.GetNextInstanceInClass(classDef.ptr, instance?.ptr) else { return nil }
        return .init(ptr: instancePtr)
    }

    /// An instance and a dictionary of its slot values
    public struct InstanceAndSlots: Equatable {
        public let className: String
        public let instanceName: String
        public let slots: [String: CLIPS.Value]
    }

    /// Get all instances and their slot values, keyed by class name then instance name
    public func getAllInstances() -> [InstanceAndSlots] {
        var instances = [InstanceAndSlots]()

        var instance: CLIPS.Instance?
        while true {
            instance = self.getNextInstance(after: instance)
            guard let instance else { break }

            let instanceName = getName(of: instance)
            let cls = getClass(of: instance)
            let className = getName(of: cls)
            let slotNames = getSlotNames(for: cls, inherit: true)
            var slotValues = [String: CLIPS.Value]()
            for slotName in slotNames {
                slotValues[slotName] = try! directGetSlot(of: instance, named: slotName)
            }
            instances.append(.init(className: className, instanceName: instanceName, slots: slotValues))
        }

        return instances
    }
}
