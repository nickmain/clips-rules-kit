// Copyright (c) 2023 David N Main

import Foundation
import CLIPSCore

extension CLIPS {
    typealias MFBuilderPtr = UnsafeMutablePointer<CLIPSCore.MultifieldBuilder>

    /// Builder for a multifield
    struct MFBuilder {
        private let builderPtr: MFBuilderPtr
        private let environment: Environment

        init(environment: Environment) {
            self.environment = environment
            builderPtr = CLIPSCore.CreateMultifieldBuilder(environment.ptr, 10)
        }

        func dispose() {
            CLIPSCore.MBDispose(builderPtr)
        }

        func createMultifield() -> MultifieldPtr {
            guard let mf = MBCreate(builderPtr) else {
                CLIPS.logger.debug("⚠️ MBCreate returned null")
                return CLIPSCore.StringToMultifield(environment.ptr, "something went wrong")
            }

            return mf
        }

        func append(boolean: Bool) {
            if boolean {
                CLIPSCore.MBAppendCLIPSLexeme(builderPtr, environment.ptr.pointee.TrueSymbol)
            } else {
                CLIPSCore.MBAppendCLIPSLexeme(builderPtr, environment.ptr.pointee.FalseSymbol)
            }
        }

        func append(integer: Int) {
            CLIPSCore.MBAppendInteger(builderPtr, Int64(integer))
        }

        func append(float: Double) {
            CLIPSCore.MBAppendFloat(builderPtr, float)
        }

        func append(symbol: String) {
            CLIPSCore.MBAppendSymbol(builderPtr, symbol)
        }

        func append(string: String) {
            CLIPSCore.MBAppendString(builderPtr, string)
        }

        func append(instanceName: String) {
            CLIPSCore.MBAppendInstanceName(builderPtr, instanceName)
        }

        /// Multifields cannot be nested and are inlined when added
        func append(multifield: MultifieldPtr) {
            CLIPSCore.MBAppendMultifield(builderPtr, multifield)
        }

        func append(fact: Fact) {
            CLIPSCore.MBAppendFact(builderPtr, fact.ptr)
        }

        func append(instance: Instance) {
            CLIPSCore.MBAppendInstance(builderPtr, instance.ptr)
        }

        func append(externalAddress: ExternalAddress) {
            CLIPSCore.MBAppendCLIPSExternalAddress(builderPtr, externalAddress.ptr)
        }

        func append(value: Value) {
            value.append(to: self)
        }
    }
}
