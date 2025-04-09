// Copyright (c) 2025 David N Main

import CLIPSCore
import OSLog

public actor CLIPSEnvironment {
    public typealias Ptr = UnsafeMutablePointer<CLIPSCore.Environment>

    /// The Logger to use for debug and warning messages
    public static var logger = Logger(subsystem: "CLIPS", category: "DEBUG")

    /// The Logger to use for default output
    public static var defaultOutputLogger = Logger(subsystem: "CLIPS", category: "DefaultOutput")

    /// Scope for saving facts
    public enum SaveScope {
        /// Save only facts from templates defined in the current module
        case localToCurrentModule

        /// Save all facts visible to the current module
        case visibleToCurrentModule

        internal var value: CLIPSCore.SaveScope {
            switch self {
            case .localToCurrentModule:   CLIPSCore.LOCAL_SAVE
            case .visibleToCurrentModule: CLIPSCore.VISIBLE_SAVE
            }
        }
    }

    internal static func from(_ pEnv: CLIPSEnvironment.Ptr) -> Self? {
        guard let context = pEnv.pointee.context else { return nil }
        return Unmanaged.fromOpaque(context).takeUnretainedValue()
    }

    // strong references to the UDF handlers
    private let udfHandlers = UDFHandlerRefs()
    private class UDFHandlerRefs {
        fileprivate var refs = [UserDefinedFunctionHandlerReference]()
    }
    internal func addUDFHandler(_ ref: UserDefinedFunctionHandlerReference) {
        udfHandlers.refs.append(ref)
    }

    private var ptr: Ptr

    // The type code used in Swift object external addresses
    internal let extAddrTypeCode: Int

    // Strong ref to the router registered with this environment
    internal let router: CLIPSRouter

    public struct CannotCreateEnvironmentError: Error {}

    /// Create an instance of the CLIPS engine.
    ///
    /// - Parameter handler: optional handler for output lines.
    ///                      Defaults to an implementation that prints to the ``CLIPSEnvironment/defaultOutputLogger``.
    ///
    public init(handler: CLIPSOutputHandler? = nil) throws(CannotCreateEnvironmentError) {
        guard let ptr = CLIPSCore.CreateEnvironment() else { throw CannotCreateEnvironmentError() }
        self.ptr = ptr
        router = CLIPSRouter(handler: handler ?? CLIPSDefaultHandler())

        // install "swift" enternal address type
        let lexPtr = CLIPSCore.CreateSymbol(ptr, "swift")!
        CLIPSCore.RetainLexeme(ptr, lexPtr)
        var addrType = CLIPSCore.externalAddressType(
                           name: lexPtr.pointee.contents,
                           shortPrintFunction: nil,
                           longPrintFunction: nil,
                           discardFunction: discardFunction(_:_:),
                           newFunction: nil,
                           callFunction: nil)
        extAddrTypeCode = Int(CLIPSCore.InstallExternalAddressType(ptr, &addrType))

        router.addStdOut()
        router.addStdErr()
        router.addStdWrn()
        router.addRouter(env: ptr)

        ptr.pointee.context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())

        #if DEBUG
        let pEnv = ptr
        Self.logger.debug("🔆 CLIPS: CreateEnvironment \(String(describing: pEnv))")
        #endif
    }

    deinit {
        // attempt to force a gc
        var value = CLIPSCore.CLIPSValue()
        _ = CLIPSCore.Eval(ptr, "true", &value)

        #if DEBUG
        let pEnv = ptr
        Self.logger.debug("♻️ CLIPS: DestroyEnvironment \(String(describing: pEnv))")
        #endif

        ptr.pointee.context = nil
        CLIPSCore.DestroyEnvironment(ptr)
    }

    // MARK: - Misc

    /// Print the CLIPS banner
    public func printBanner() {
        CLIPSCore.PrintBanner(ptr)
    }

    /// Add a logical I/O name that will be recognized by the output handler.
    public func addLogicalIO(name: String) {
        router.add(name: name)
    }

    /// Attempt to force a garbage collection
    public func gc() {
        _ = try? eval("true")
    }

    /// Execute the passed closure with access to the underlying environment pointer
    public func withPtr<R, E: Error>(_ body: (Ptr) throws(E) -> R) throws(E) -> R {
        try body(ptr)
    }

    // MARK: - Loading, Saving and Building

    /// Load a file
    ///
    /// - Throws: ``CLIPSLoadError``
    public func load(path: String) throws(CLIPSLoadError) {
        let err = CLIPSCore.Load(ptr, path)
        guard err == CLIPSCore.LE_NO_ERROR else {
            throw CLIPSLoadError.from(err)
        }
    }

    /// Load a binary construct file
    ///
    /// - Returns: false if not successful
    public func loadBinary(path: String) -> Bool {
        CLIPSCore.Bload(ptr, path)
    }

    /// Save a binary construct file
    ///
    /// - Returns: false if not successful
    public func saveBinary(path: String) -> Bool {
        CLIPSCore.Bsave(ptr, path)
    }

    /// Load and run a batch command file
    ///
    /// - Returns: false if not successful
    public func loadBatch(path: String) -> Bool {
        CLIPSCore.BatchStar(ptr, path)
    }

    /// Build a construct from a string
    ///
    /// - Throws: ``CLIPSBuildError``
    public func build(_ construct: String) throws(CLIPSBuildError) {
        let err = CLIPSCore.Build(ptr, construct)
        switch err {
        case CLIPSCore.BE_COULD_NOT_BUILD_ERROR: throw CLIPSBuildError.couldNotBuild
        case CLIPSCore.BE_CONSTRUCT_NOT_FOUND_ERROR: throw CLIPSBuildError.constructNotFound
        case CLIPSCore.BE_PARSING_ERROR: throw CLIPSBuildError.parsingError
        default: return
        }
    }

    // MARK: - Running

    /// Reset the environment
    public func reset() {
        CLIPSCore.Reset(ptr)
    }

    /// Clear the environment
    public func clear() {
        CLIPSCore.Clear(ptr)
    }

    /// Run rules.
    ///
    /// - Parameter count: the max number of rules to run. -1 (default) for unlimited.
    /// - Returns: number of rules that were fired
    @discardableResult
    public func run(count: Int64 = -1 ) -> Int64 {
        #if DEBUG
        Self.logger.debug("🔻 CLIPS: running rules (count: \(count))")
        #endif

        let actual = CLIPSCore.Run(ptr, count)

        #if DEBUG
        Self.logger.debug("🔺 CLIPS: finished rules (actual: \(actual))")
        #endif

        return actual
    }

    /// Call a CLIPS function.
    ///
    /// - Throws: ``CLIPSFunctionCallBuilderError``
    @discardableResult
    public func call(_ funcName: String, _ args: CLIPSValue...) throws(CLIPSFunctionCallBuilderError) -> CLIPSValue {
        // use a function call builder to create and invoke
        guard let fcBuilder = CLIPSCore.CreateFunctionCallBuilder(ptr, 10) else {
            throw CLIPSFunctionCallBuilderError.nullPointer
        }

        for arg in args {
            var argValue = arg.asCLIPSValue(pEnv: ptr)
            CLIPSCore.FCBAppend(fcBuilder, &argValue)
        }

        var value = CLIPSCore.CLIPSValue()
        let err = CLIPSCore.FCBCall(fcBuilder, funcName, &value)
        CLIPSCore.FCBDispose(fcBuilder)

        guard err == CLIPSCore.FCBE_NO_ERROR else {
            throw CLIPSFunctionCallBuilderError.from(err)
        }

        return CLIPSValue.from(value: value, env: self, pEnv: ptr)
    }

    /// Evaluate an expression and return the result
    ///
    /// - Throws: ``CLIPSEvalError``
    @discardableResult
    public func eval(_ expression: String) throws(CLIPSEvalError) -> CLIPSValue? {
        var value = CLIPSCore.CLIPSValue()

        let err = CLIPSCore.Eval(ptr, expression, &value)
        switch err {
        case CLIPSCore.EE_PARSING_ERROR: throw CLIPSEvalError.parseError
        case CLIPSCore.EE_PROCESSING_ERROR: throw CLIPSEvalError.processingError
        default: break
        }

        return CLIPSValue.from(value: value, env: self, pEnv: ptr)
    }

    // MARK: - Modules

    public var currentModule: CLIPSModule { .init(ptr: CLIPSCore.GetCurrentModule(ptr), env: self) }

    public func findModule(named name: String) -> CLIPSModule? {
        guard let modulePtr = CLIPSCore.FindDefmodule(ptr, name) else { return nil }
        return .init(ptr: modulePtr, env: self)
    }

    public func getFirstModule() -> CLIPSModule? {
        guard let pModule = CLIPSCore.GetNextDefmodule(ptr, nil) else { return nil }
        return .init(ptr: pModule, env: self)
    }

    public func getModuleNames() -> [String] {
        var clipsValue = CLIPSCore.CLIPSValue()
        CLIPSCore.GetDefmoduleList(ptr, &clipsValue)
        let value = CLIPSValue.from(value: clipsValue, env: self, pEnv: ptr)
        return switch value {
        case .multifield(let values):
            values.map { $0.asString }
        default:
            []
        }
    }

    // MARK: - External Addresses

    // MARK: - Templates

    public func findTemplate(named name: String) -> CLIPSTemplate? {
        guard let templatePtr = CLIPSCore.FindDeftemplate(ptr, name) else { return nil }
        return .init(ptr: templatePtr, env: self)
    }

    public func getFirstTemplate() -> CLIPSTemplate? {
        guard let pTemplate = CLIPSCore.GetNextDeftemplate(ptr, nil) else { return nil }
        return .init(ptr: pTemplate, env: self)
    }

    // MARK: - Classes

    public func findClass(named name: String) -> CLIPSClass? {
        guard let classPtr = CLIPSCore.FindDefclass(ptr, name) else { return nil }
        return .init(ptr: classPtr, env: self)
    }

    public func getFirstClass() -> CLIPSClass? {
        guard let pClass = CLIPSCore.GetNextDefclass(ptr, nil) else { return nil }
        return .init(ptr: pClass, env: self)
    }

    // MARK: - Instances

    public func getFirstInstance() -> CLIPSInstance? {
        guard let pInstance = CLIPSCore.GetNextInstance(ptr, nil) else { return nil }
        return .init(ptr: pInstance, env: self)
    }

    /// Whether the set of instances and instance values has changed since this value was set to false
    public var instancesChanged: Bool {
        get { CLIPSCore.GetInstancesChanged(ptr) }
        set { CLIPSCore.SetInstancesChanged(ptr, newValue) }
    }

    /// Find an instance by name.
    ///
    /// - Parameters:
    ///   - name: the instance name to find
    ///   - module: the module to search, nil (default) for current module
    ///   - searchImports: whether to also search the module imports, default false
    /// - Returns: the instance or nil if not found
    ///
    public func findInstance(named name: String, in module: CLIPSModule? = nil, searchImports: Bool = false) -> CLIPSInstance? {
        if let ptr = CLIPSCore.FindInstance(self.ptr, module?.ptr, name, searchImports) {
            .init(ptr: ptr, env: self)
        } else {
            nil
        }
    }

    /// Create an instance from a string.
    ///
    /// - Throws: ``CLIPSMakeInstanceError``
    ///
    @discardableResult
    public func make(instance: String) throws -> CLIPSInstance {
        guard let instPtr = CLIPSCore.MakeInstance(ptr, instance) else {
            let err = CLIPSCore.GetMakeInstanceError(ptr)
            throw CLIPSMakeInstanceError(kind: err, instance: instance)
        }

        return .init(ptr: instPtr, env: self)
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
    public func saveInstances(to filename: String, scope: SaveScope) -> Int {
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
    public func saveBinaryInstances(to filename: String, scope: SaveScope) -> Int {
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

    /// Use a closure to build instances.
    ///
    /// - Throws: ``InstanceBuilderError`` or ``PutSlotError``
    ///
    public func buildInstances(_ body: (borrowing CLIPSInstanceBuilder) throws -> Void) throws {
        let builder = try CLIPSInstanceBuilder(env: self, pEnv: ptr)
        try body(builder)
    }

    // MARK: - Facts

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

    /// Assert a fact from a string.
    ///
    /// - Returns: the asserted fact
    /// - Throws: ``CLIPSAssertStringError``
    @discardableResult
    public func assert(fact: String) throws(CLIPSAssertStringError) -> CLIPSFact {
        guard let factPtr = CLIPSCore.AssertString(ptr, fact) else {
            let err = CLIPSCore.GetAssertStringError(ptr)
            throw CLIPSAssertStringError(kind: err, fact: fact)
        }

        return .init(ptr: factPtr, env: self)
    }

    /// Retract all facts.
    ///
    /// - Throws: ``CLIPSRetractError``
    public func retractAllFacts() throws(CLIPSRetractError) {
        let err = CLIPSCore.RetractAllFacts(ptr)
        if err != CLIPSCore.RE_NO_ERROR {
            throw CLIPSRetractError.from(err)
        }
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
    public func saveFacts(to filename: String, scope: SaveScope) -> Int {
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
    public func saveBinaryFacts(to filename: String, scope: SaveScope) -> Int {
        CLIPSCore.BinarySaveFacts(ptr, filename, scope.value)
    }

    /// Load facts from a string
    ///
    /// - Returns: number of facts loaded or -1 of there was an error
    public func loadFacts(fromString string: String) -> Int {
        CLIPSCore.LoadFactsFromString(ptr, string, Int.max)
    }

    public func getFirstFact() -> CLIPSFact? {
        guard let factPtr = CLIPSCore.GetNextFact(ptr, nil) else { return nil }
        return .init(ptr: factPtr, env: self)
    }

    /// Use a closure to build and assert facts.
    ///
    /// - Throws: ``CLIPSFactBuilderError`` or ``CLIPSPutSlotError``
    ///
    public func buildFacts(_ body: (borrowing CLIPSFactBuilder) throws -> Void) throws {
        let builder = try CLIPSFactBuilder(env: self, pEnv: ptr)
        try body(builder)
    }

    // MARK: - External Address

    /// Create an external address pointing at the given object.
    /// The object is Swift-retained by the CLIPS external address and will be
    /// Swift-released when the address is garbage collected.
    ///
    public func createExternalAddress(_ object: AnyObject) -> CLIPSExternalAddress {
        // pass a retained value so that the external address owns a reference
        // count on the object
        let objectPtr = UnsafeMutableRawPointer(Unmanaged.passRetained(object).toOpaque())

        return .init(ptr: CLIPSCore.CreateExternalAddress(self.ptr, objectPtr, UInt16(extAddrTypeCode)),
                     env: self)
    }

    /// Get the object from an external address that was created by the
    /// ``CLIPSEnvironment/createExternalAddress(_:)`` method.
    ///
    public func object(from externalAddress: CLIPSExternalAddress) -> AnyObject? {
        guard externalAddress.ptr.pointee.type == extAddrTypeCode else { return nil }

        guard let ptr = externalAddress.ptr.pointee.contents else { return nil }

        // Take an unretained value so that the swift reference count
        // is incremented
        return Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue()
    }

    // MARK: - Watch

    /// Set the watch state for the given item type
    public func watch(for type: CLIPSWatchItemType, enabled: Bool) {
        CLIPSCore.SetWatchState(ptr, type.item, enabled)
    }

    /// Get the watch state for the given item type
    public func isWatchEnabled(for type: CLIPSWatchItemType) -> Bool {
        CLIPSCore.GetWatchState(ptr, type.item)
    }

    /// Set the watch state for all the items
    public func watchAll(enabled: Bool) {
        CLIPSCore.SetWatchState(ptr, CLIPSCore.ALL, enabled)
    }

    // MARK: - User Defined Functions

    /// Register a User Defined Function with CLIPS
    ///
    /// - Parameters:
    ///    - clipsName: the function name used in CLIPS code
    ///    - returnTypes: the types that can returned, default is
    ///                   any type
    ///    - argTypes: the argument types, default is none
    ///    - argCount: the number of arguments that can be passed,
    ///                default is unbounded
    ///    - handler: the callback to handle an invocation of the
    ///               function coming in from CLIPS
    ///
    public func addUserDefinedFunction(
        named clipsName: String,
        returnTypes: [CLIPSUserDefinedFunction.UserDefinedType] = [.any],
        argTypes: CLIPSUserDefinedFunction.UDFArguentTypes = .init(),
        argCount: ClosedRange<UInt16>? = nil,
        handler: @escaping CLIPSUserDefinedFunction.Handler
    ) throws {
        let handlerRef = CLIPSEnvironment.UserDefinedFunctionHandlerReference(handler, environment: self)
        self.addUDFHandler(handlerRef)

        // CLIPS stores the native func name as a char* and
        // Swift will invalidate that when clipsName goes out of
        // scope, so we need to copy and retain the string
        guard let lexPtr = CLIPSCore.CreateString(ptr, clipsName) else {
            throw CLIPSAddUDFError.unexpected
        }

        CLIPSCore.RetainLexeme(ptr, lexPtr)
        let namePtr = lexPtr.pointee.contents

        let handlerPtr = UnsafeMutableRawPointer(Unmanaged.passUnretained(handlerRef).toOpaque())

        let err = AddUDF(ptr,
                         namePtr,
                         returnTypes.asString,
                         argCount?.lowerBound ?? 0,
                         argCount?.upperBound ?? UInt16.max,
                         argTypes.asString,
                         commonUserDefinedFunction(_:_:_:),
                         namePtr,
                         handlerPtr)

        if err != CLIPSCore.AUE_NO_ERROR {
            throw CLIPSAddUDFError.from(err)
        }
    }
}
