// Copyright (c) 2025 David N Main

import Foundation
import CLIPSCore

public enum CLIPSUserDefinedFunction {

    typealias UserDefValue = UnsafeMutablePointer<CLIPSCore.UDFValue>
    typealias UserDefContext = UnsafeMutablePointer<CLIPSCore.UDFContext>

    /// The callback type for a User Defined Function
    public typealias Handler = (Invocation) -> Void

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
    public struct Invocation {
        private let context: UserDefContext
        private let returnValue: UserDefValue

        /// The current environment
        public let environment: CLIPSEnvironment
        private let pEnv: CLIPSEnvironment.Ptr

        init(context: UnsafeMutablePointer<UDFContext>, returnValue: UnsafeMutablePointer<UDFValue>, environment: CLIPSEnvironment, pEnv: CLIPSEnvironment.Ptr) {
            self.context = context
            self.returnValue = returnValue
            self.environment = environment
            self.pEnv = pEnv
        }

        /// The number of arguments passed
        public var argCount: Int {
            Int(CLIPSCore.UDFArgumentCount(context))
        }

        /// Get all the passed arguments
        public func getArguments() -> [CLIPSValue] {
            .from(context: context)
        }

        /// Set the function result
        public func setReturn(value: CLIPSValue) {
            value.store(in: returnValue, env: environment, pEnv: pEnv)
        }

        /// Indicate that an error has occurred and execution should stop
        public func throwError() {
            CLIPSCore.UDFThrowError(context)
        }

        /// Set an error value that can be retrieved via "(get-error)".
        /// Execution is not stopped.
        public func setError(_ value: CLIPSValue) {
            // this will retain the value
            CLIPSCore.SetErrorValue(pEnv, value.asCLIPSValue(pEnv: pEnv).header)
        }
    }
}
