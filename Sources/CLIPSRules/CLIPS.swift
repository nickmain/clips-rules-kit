// Copyright (c) 2023 David N Main - All Rights Reserved.

import Foundation
import os
import CLIPSCore

public typealias ClipsEnv = UnsafeMutablePointer<Environment>

public typealias UserDefFunc = ((UnsafeMutablePointer<Environment>?,
                                 UnsafeMutablePointer<UDFContext>?,
                                 UnsafeMutablePointer<UDFValue>?) -> Void)

class DefaultHandler: CLIPSOutputHandler {
    func handle(line: CLIPSOutputLine) {
        switch line {
        case .stdout(line: let line): print("🔸 \(line)")
        case .error(line: let line): print("🆘 \(line)")
        case .warning(line: let line): print("⚠️ \(line)")
        case .named(name: let name, line: let line):
            print("🔹 \(name): \(line)")
        }
    }
}

/// An instance of the CLIPS engine.
public actor CLIPS {
    /// The ``Logger`` to use
    public static var logger = Logger()

    private let env: ClipsEnv
    private let router: Router
    private let externalAddr: ExternalAddressType

    static func from(_ env: ClipsEnv) -> CLIPS? {
        guard let context = env.pointee.context else { return nil }
        return Unmanaged.fromOpaque(context).takeUnretainedValue()
    }

    /// Create an instance of the CLIPS engine.
    ///
    /// - Parameter handler: optional handler for output lines.
    ///                      Defaults to an implementation that prints to the
    ///                      console.
    ///
    public init(handler: CLIPSOutputHandler? = nil) {
        router = Router(handler: handler ?? DefaultHandler())
        env = CreateEnvironment()

        let ptr = env
        Self.logger.debug("🔆 CLIPS: CreateEnvironment \(String(describing: ptr))")

        router.addStdOut()
        router.addStdErr()
        router.addStdWrn()
        router.addRouter(env: env)

        externalAddr = ExternalAddressType(name: "swift", env: env)

        env.pointee.context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
    }

    deinit {
        let ptr = env
        Self.logger.debug("♻️ CLIPS: DestroyEnvironment \(String(describing: ptr))")
        env.pointee.context = nil
        DestroyEnvironment(env)
    }

    /// Add a logical I/O name that will be recognized by the output handler.
    public func addLogicalIO(name: String) {
        router.add(name: name)
    }

    /// Print the CLIPS banner
    public func printBanner() {
        PrintBanner(env)
    }
    
    /// Load a file
    public func load(path: String) {
        Load(env, path)
    }

    /// Reset the environment
    public func reset() {
        Reset(env)
    }

    /// Clear the environment
    public func clear() {
        Clear(env)
    }

    /// Run rules.
    ///
    /// - Parameter count: the max number of rules to run. -1 (default) for unlimited.
    /// - Returns: number of rules that were fired
    @discardableResult
    public func run(count: Int64 = -1 ) -> Int64 {
        Self.logger.debug("🔻 CLIPS: running rules (count: \(count))")
        let actual = Run(env, count)
        Self.logger.debug("🔺 CLIPS: finished rules (actual: \(actual))")
        return actual
    }

    /// Evaluate an expression and return the result
    ///
    /// - Throws: ``CLIPSEvalError``
    @discardableResult
    public func eval(_ expression: String) throws -> Value? {
        var value = CLIPSValue()

        let err = Eval(env, expression, &value)
        switch err {
        case EE_PARSING_ERROR: throw CLIPSEvalError.parseError
        case EE_PROCESSING_ERROR: throw CLIPSEvalError.processingError
        default: break
        }

        return Value.from(value: value, env: env)
    }

    /// Build a construct from a string
    ///
    /// - Throws: ``CLIPSBuildError``
    public func build(_ construct: String) throws {
        let err = Build(env, construct)
        switch err {
        case BE_COULD_NOT_BUILD_ERROR: throw CLIPSBuildError.couldNotBuild
        case BE_CONSTRUCT_NOT_FOUND_ERROR: throw CLIPSBuildError.constructNotFound
        case BE_PARSING_ERROR: throw CLIPSBuildError.parsingError
        default: return
        }
    }

    // MARK: - Fact APIs
    
    /// Assert a fact from a string.
    ///
    /// - Returns: a pointer to the asserted fact
    /// - Throws: ``CLIPSAssertStringError``
    @discardableResult
    public func assert(fact: String) throws -> FactPtr {
        guard let factPtr = AssertString(env, fact) else {
            let err = GetAssertStringError(env)
            throw CLIPSAssertStringError(kind: err, fact: fact)
        }

        return factPtr
    }

    /// Retract a fact.
    ///
    /// - Parameter fact: the fact to retract
    /// - Throws: ``CLIPSRetractError``
    public func retract(fact: FactPtr) async throws {
        let err = Retract(fact)
        if err != RE_NO_ERROR {
            throw CLIPSRetractError.from(err)
        }
    }

    /// Retract all facts.
    ///
    /// - Throws: ``CLIPSRetractError``
    public func retractAllFacts() throws {
        let err = RetractAllFacts(env)
        if err != RE_NO_ERROR {
            throw CLIPSRetractError.from(err)
        }
    }

    /// Whether the set of facts have changed since this value was set to false
    public var factListChanged: Bool {
        get { GetFactListChanged(env) }
        set { SetFactListChanged(env, newValue) }
    }

    /// Whether the set of instances and instance values has changed since this value was set to false
    public var instancesChanged: Bool {
        get { GetInstancesChanged(env) }
        set { SetInstancesChanged(env, newValue) }
    }

    /// Whether duplicate facts are allowed - initially false.
    public var duplicateFactsAllowed: Bool {
        get { GetFactDuplication(env) }
        set { SetFactDuplication(env, newValue) }
    }

    // MARK: - Instance APIs
    
    /// Create an instance from a string.
    ///
    /// - Returns: a pointer to the instance
    /// - Throws: ``CLIPSMakeInstanceError``
    @discardableResult
    public func make(instance: String) throws -> InstancePtr {
        guard let instPtr = MakeInstance(env, instance) else {
            let err = GetMakeInstanceError(env)
            throw CLIPSMakeInstanceError(kind: err, instance: instance)
        }
                
        return instPtr
    }

    /// Unmake an instance.
    ///
    /// - Parameter instance: the instance to unmake
    /// - Throws: ``CLIPSUnmakeInstanceError``
    public func unmake(instance: InstancePtr) async throws {
        let err = UnmakeInstance(instance)
        if err != UIE_NO_ERROR {
            throw CLIPSUnmakeInstanceError.from(err)
        }
    }

    // MARK: - Misc API

    /// Create and retain a new symbol
    public func make(symbol: String) -> LexemePtr {
        let lexPtr = CreateSymbol(env, symbol)!
        RetainLexeme(env, lexPtr)
        return lexPtr
    }

    /// Create and retain a new string
    public func make(string: String) -> LexemePtr {
        let lexPtr = CreateString(env, string)!
        RetainLexeme(env, lexPtr)
        return lexPtr
    }

    /// Create and retain a new instance name
    public func make(name: String) -> LexemePtr {
        let lexPtr = CreateInstanceName(env, name)!
        RetainLexeme(env, lexPtr)
        return lexPtr
    }

    /// Perform the callback within this actor isolation
    public func perform<T>(callback: (ClipsEnv) throws -> T) throws -> T {
        try callback(env)
    }

    /// Perform the callback within this actor isolation
    public func perform<T>(callback: (ClipsEnv) -> T) -> T {
        callback(env)
    }

    public func addUserDefinedFunction(named clipsName: String, nativeName: String) throws {

//        let nameLex = CreateString(env, nativeName)
//        RetainLexeme(env, nameLex)
//
//        let err = AddUDF(env,
//                         clipsName,
//                         <#T##UnsafePointer<CChar>!#>,
//                         <#T##UInt16#>, <#T##UInt16#>,
//                         <#T##UnsafePointer<CChar>!#>,
//                         <#T##((UnsafeMutablePointer<Environment>?, UnsafeMutablePointer<UDFContext>?, UnsafeMutablePointer<UDFValue>?) -> Void)!##((UnsafeMutablePointer<Environment>?, UnsafeMutablePointer<UDFContext>?, UnsafeMutablePointer<UDFValue>?) -> Void)!##(UnsafeMutablePointer<Environment>?, UnsafeMutablePointer<UDFContext>?, UnsafeMutablePointer<UDFValue>?) -> Void#>,
//                         nameLex?.pointee.contents,
//                         nil)
//
//        guard err == AUE_NO_ERROR else {
//            switch err {
//            case AUE_MIN_EXCEEDS_MAX_ERROR: throw CLIPSUserFunctionError.minExceedsMax
//            case AUE_FUNCTION_NAME_IN_USE_ERROR: throw CLIPSUserFunctionError.nameInUse
//            case AUE_INVALID_ARGUMENT_TYPE_ERROR: throw CLIPSUserFunctionError.invalidArgumentType
//            case AUE_INVALID_RETURN_TYPE_ERROR: throw CLIPSUserFunctionError.invalidReturnType
//            default: return
//            }
//        }


//
//        AddUDFError AddUDF(
//           Environment *env,
//           const char *clipsName,
//           const char *returnTypes,
//           unsigned short minArgs,
//           unsigned short maxArgs,
//           const char *argTypes,
//           UserDefinedFunction *cfp,
//           const char *cName,
//           void *context);

    }
}
