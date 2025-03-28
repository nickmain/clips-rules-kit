// Copyright (c) 2025 David N Main

import Foundation
import CLIPSCore

extension CLIPSEnvironment {

    // Class wrapper for UDF handler closure to allow passing a context
    // pointer when adding the UDF to CLIPS
    class UserDefinedFunctionHandlerReference {
        internal let handler: CLIPSUserDefinedFunction.Handler
        internal let environment: CLIPSEnvironment

        init(_ handler: @escaping CLIPSUserDefinedFunction.Handler, environment: CLIPSEnvironment) {
            self.handler = handler
            self.environment = environment
        }
        static func from(_ contextPtr: CLIPSUserDefinedFunction.UserDefContext) -> Self? {
            guard let context = contextPtr.pointee.context else { return nil }
            return Unmanaged.fromOpaque(context).takeUnretainedValue()
        }
    }
}

// The common User Defined Function callback
func commonUserDefinedFunction(
    _ envPtr: CLIPSEnvironment.Ptr?,
    _ udfContext: CLIPSUserDefinedFunction.UserDefContext?,
    _ returnValue: CLIPSUserDefinedFunction.UserDefValue?
) {
    guard let udfContext,
          let envPtr,
          let returnValue,
          let handler = CLIPSEnvironment.UserDefinedFunctionHandlerReference.from(udfContext)
    else {
        CLIPSEnvironment.logger.debug("⚠️ Bad call to UDF")
        return
    }

    let invocation = CLIPSUserDefinedFunction.Invocation(context: udfContext, returnValue: returnValue, environment: handler.environment, pEnv: envPtr)
    handler.handler(invocation)
}

extension Array where Element == CLIPSUserDefinedFunction.UserDefinedType {

    // The string formed by joining the types codes
    var asString: String {
        self.map(\.rawValue).joined()
    }
}

extension Array where Element == CLIPSRules.CLIPSValue {

    // Get argument values from a UDF context
    static func from(context: CLIPSUserDefinedFunction.UserDefContext) -> [CLIPSValue] {
        guard let pEnv = context.pointee.environment,
              let env = CLIPSEnvironment.from(pEnv)
        else { return [] }

        var values: [CLIPSValue] = []
        var value = CLIPSCore.UDFValue()

        while context.pointee.lastArg != nil {
            if CLIPSCore.UDFNextArgument(context, 0b11111111111, &value) {
                let value = CLIPSRules.CLIPSValue.from(udfValue: value, env: env, pEnv: pEnv)
                values.append(value)
            }
        }

        return values
    }
}
