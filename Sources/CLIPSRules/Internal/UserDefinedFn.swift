// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation
import CLIPSCore

extension CLIPS {
    typealias UserDefValue = UnsafeMutablePointer<CLIPSCore.UDFValue>
    typealias UserDefContext = UnsafeMutablePointer<CLIPSCore.UDFContext>

    // Class wrapper for UDF handler closure to allow passing a context
    // pointer when adding the UDF to CLIPS
    class UserDefinedFunctionHandlerReference {
        internal let handler: CLIPS.UserDefinedFunctionHandler
        internal let environment: Environment

        init(_ handler: @escaping UserDefinedFunctionHandler, environment: Environment) {
            self.handler = handler
            self.environment = environment
        }
        static func from(_ contextPtr: UserDefContext) -> Self? {
            guard let context = contextPtr.pointee.context else { return nil }
            return Unmanaged.fromOpaque(context).takeUnretainedValue()
        }
    }
}

// The common User Defined Function callback
func commonUserDefinedFunction(
    _ envPtr: CLIPS.EnvironmentPtr?,
    _ udfContext: CLIPS.UserDefContext?,
    _ returnValue: CLIPS.UserDefValue?
) {
    guard let udfContext,
          let returnValue,
          let handler = CLIPS.UserDefinedFunctionHandlerReference.from(udfContext)
    else {
        CLIPS.logger.debug("⚠️ Bad call to UDF")
        return
    }

    let invocation = CLIPS.UserDefinedFunctionInvocation(context: udfContext, returnValue: returnValue, environment: handler.environment)
    handler.handler(invocation)
}

extension Array where Element == CLIPS.UserDefinedType {

    // The string formed by joining the types codes
    var asString: String {
        self.map(\.rawValue).joined()
    }
}

extension Array where Element == CLIPS.Value {

    // Get argument values from a UDF context
    static func from(context: CLIPS.UserDefContext) -> [CLIPS.Value] {
        guard let env = context.pointee.environment,
              let engine = CLIPS.Engine.from(env)
            else { return [] }

        var values: [CLIPS.Value] = []
        var value = CLIPSCore.UDFValue()

        while context.pointee.lastArg != nil {
            if CLIPSCore.UDFNextArgument(context, 0b11111111111, &value) {
                let value = CLIPS.Value.from(udfValue: value, environment: engine.environment)
                values.append(value)
            }
        }

        return values
    }
}
