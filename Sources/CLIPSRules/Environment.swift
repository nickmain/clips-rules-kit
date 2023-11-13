// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation
import CLIPSCore

extension CLIPS {

    /// Pointer to the CLIPS Environment
    public typealias EnvironmentPtr = UnsafeMutablePointer<CLIPSCore.Environment>

    /// A wrapper around a CLIPS environment
    public struct Environment {

        /// The wrapped CLIPS Environment.
        public let ptr: EnvironmentPtr

        // The type code used in Swift object external addresses
        internal let extAddrTypeCode: Int

        // Strong ref to the router registered with this environment
        internal let router: Router

        internal init(ptr: EnvironmentPtr, extAddrTypeCode: Int, router: Router) {
            self.ptr = ptr
            self.extAddrTypeCode = extAddrTypeCode
            self.router = router
        }
    }
}

extension CLIPS.Environment {

    /// Add a logical I/O name that will be recognized by the output handler.
    public func addLogicalIO(name: String) {
        router.add(name: name)
    }

    /// Print the CLIPS banner
    public func printBanner() {
        CLIPSCore.PrintBanner(ptr)
    }

    /// Load a file
    ///
    /// - Throws: ``LoadError``
    public func load(path: String) throws {
        let err = CLIPSCore.Load(ptr, path)
        guard err == CLIPSCore.LE_NO_ERROR else {
            throw CLIPS.LoadError.from(err)
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

    /// Reset the environment
    public func reset() {
        CLIPSCore.Reset(ptr)
    }

    /// Clear the environment
    public func clear() {
        CLIPSCore.Clear(ptr)
    }

    /// Attempt to force a garbage collection
    public func gc() {
        _ = try? eval("true")
    }

    /// Run rules.
    ///
    /// - Parameter count: the max number of rules to run. -1 (default) for unlimited.
    /// - Returns: number of rules that were fired
    @discardableResult
    public func run(count: Int64 = -1 ) -> Int64 {
        #if DEBUG
        CLIPS.logger.debug("🔻 CLIPS: running rules (count: \(count))")
        #endif

        let actual = CLIPSCore.Run(ptr, count)

        #if DEBUG
        CLIPS.logger.debug("🔺 CLIPS: finished rules (actual: \(actual))")
        #endif

        return actual
    }

    /// Call a CLIPS function.
    ///
    /// - Throws: ``FunctionCallBuilderError``
    @discardableResult
    public func call(_ funcName: String, _ args: CLIPS.Value...) throws -> CLIPS.Value {
        // use a function call builder to create and invoke
        guard let fcBuilder = CLIPSCore.CreateFunctionCallBuilder(ptr, 10) else {
            throw CLIPS.FunctionCallBuilderError.nullPointer
        }

        for arg in args {
            var argValue = arg.asCLIPSValue(environment: self)
            CLIPSCore.FCBAppend(fcBuilder, &argValue)
        }

        var value = CLIPSCore.CLIPSValue()
        let err = CLIPSCore.FCBCall(fcBuilder, funcName, &value)
        CLIPSCore.FCBDispose(fcBuilder)

        guard err == CLIPSCore.FCBE_NO_ERROR else {
            throw CLIPS.FunctionCallBuilderError.from(err)
        }

        return CLIPS.Value.from(value: value, environment: self)
    }

    /// Evaluate an expression and return the result
    ///
    /// - Throws: ``EvalError``
    @discardableResult
    public func eval(_ expression: String) throws -> CLIPS.Value? {
        var value = CLIPSCore.CLIPSValue()

        let err = CLIPSCore.Eval(ptr, expression, &value)
        switch err {
        case CLIPSCore.EE_PARSING_ERROR: throw CLIPS.EvalError.parseError
        case CLIPSCore.EE_PROCESSING_ERROR: throw CLIPS.EvalError.processingError
        default: break
        }

        return CLIPS.Value.from(value: value, environment: self)
    }

    /// Build a construct from a string
    ///
    /// - Throws: ``BuildError``
    public func build(_ construct: String) throws {
        let err = CLIPSCore.Build(ptr, construct)
        switch err {
        case CLIPSCore.BE_COULD_NOT_BUILD_ERROR: throw CLIPS.BuildError.couldNotBuild
        case CLIPSCore.BE_CONSTRUCT_NOT_FOUND_ERROR: throw CLIPS.BuildError.constructNotFound
        case CLIPSCore.BE_PARSING_ERROR: throw CLIPS.BuildError.parsingError
        default: return
        }
    }
}
