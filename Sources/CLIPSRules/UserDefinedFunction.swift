// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation
import CLIPSCore

extension CLIPS {
    
    /// The callback type for a User Defined Function
    public typealias UserDefinedFunctionHandler = (UserDefinedFunctionInvocation) -> Void

    /// Argument and return type codes for User Defined Functions
    public enum UserDefinedType: String {
        case boolean = "b"
        case double = "d"
        case external = "e"
        case fact = "f"
        case instance = "i"
        case integer = "l"
        case multifield = "m"
        case instanceName = "n"
        case string = "s"
        case symbol = "y"
        case void = "v"
        case any = "*"
    }

    /// The argument types for a User Defined Function
    public struct UDFArguentTypes {
        let defaultTypes: [UserDefinedType]
        let positionalTypes: [[UserDefinedType]]

        /// - Parameters:
        ///   - defaultTypes: the union of types that is the default for
        ///                   any argument not given a set of positional types.
        ///                   Omit for the default being any type.
        ///   - positionalTypes: the types allowed for each argument position.
        ///                      Empty in a position means use the default types.
        ///                      (Note: this appears to be broken in CLIPS, always
        ///                      provide types(s) for a position).
        ///                      Omit for no positional type constraints.
        public init(defaultTypes: [UserDefinedType] = [], positionalTypes: [[UserDefinedType]] = []) {
            self.defaultTypes = defaultTypes
            self.positionalTypes = positionalTypes
        }

        // The argTypes string expected by CLIPS
        var asString: String {
            defaultTypes.asString + positionalTypes.map { ";" + $0.asString }.joined()
        }
    }

    /// The context of a User Defined Function invocation
    public struct UserDefinedFunctionInvocation {
        private let context: UserDefContext
        private let returnValue: UserDefValue

        /// The current environment
        public let environment: Environment

        init(context: UnsafeMutablePointer<UDFContext>, returnValue: UnsafeMutablePointer<UDFValue>, environment: Environment) {
            self.context = context
            self.returnValue = returnValue
            self.environment = environment
        }

        /// The number of arguments passed
        public var argCount: Int {
            Int(CLIPSCore.UDFArgumentCount(context))
        }

        /// Get all the passed arguments
        public func getArguments() -> [Value] {
            .from(context: context)
        }

        /// Set the function result
        public func setReturn(value: Value) {
            value.store(in: returnValue, environment: environment)
        }

        /// Indicate that an error has occurred and execution should stop
        public func throwError() {
            CLIPSCore.UDFThrowError(context)
        }

        /// Set an error value that can be retrieved via "(get-error)".
        /// Execution is not stopped.
        public func setError(_ value: Value) {
            // this will retain the value
            CLIPSCore.SetErrorValue(environment.ptr, value.asCLIPSValue(environment: environment).header)
        }
    }
}

extension CLIPS.Environment {

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
    public func addUserDefinedFunction(
        named clipsName: String,
        returnTypes: [CLIPS.UserDefinedType] = [.any],
        argTypes: CLIPS.UDFArguentTypes = .init(),
        argCount: ClosedRange<UInt16>? = nil,
        handler: @escaping CLIPS.UserDefinedFunctionHandler
    ) throws {
        let handlerRef = CLIPS.UserDefinedFunctionHandlerReference(handler, environment: self)
        guard let engine = CLIPS.Engine.from(self.ptr) else {
            throw CLIPS.AddUDFError.unexpected
        }
        engine.addUDFHandler(handlerRef)

        // CLIPS stores the native func name as a char* and
        // Swift will invalidate that when clipsName goes out of
        // scope, so we need to copy and retain the string
        guard let lexPtr = CLIPSCore.CreateString(ptr, clipsName) else {
            throw CLIPS.AddUDFError.unexpected
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
            throw CLIPS.AddUDFError.from(err)
        }
    }
}
