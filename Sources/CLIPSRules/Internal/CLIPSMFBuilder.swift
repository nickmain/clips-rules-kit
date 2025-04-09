// Copyright (c) 2025 David N Main

import CLIPSCore

/// Builder for a multifield
struct CLIPSMFBuilder {
    typealias Ptr = UnsafeMutablePointer<CLIPSCore.MultifieldBuilder>

    private let ptr: Ptr
    private let pEnv: CLIPSEnvironment.Ptr

    init(pEnv: CLIPSEnvironment.Ptr) {
        self.pEnv = pEnv
        ptr = CLIPSCore.CreateMultifieldBuilder(pEnv, 10)
    }

    func dispose() {
        CLIPSCore.MBDispose(ptr)
    }

    func createMultifield() -> CLIPSMultifieldPtr {
        guard let mf = MBCreate(ptr) else {
            CLIPSEnvironment.logger.debug("⚠️ MBCreate returned null")
            return CLIPSCore.StringToMultifield(pEnv, "something went wrong")
        }

        return mf
    }

    func append(boolean: Bool) {
        if boolean {
            CLIPSCore.MBAppendCLIPSLexeme(ptr, pEnv.pointee.TrueSymbol)
        } else {
            CLIPSCore.MBAppendCLIPSLexeme(ptr, pEnv.pointee.FalseSymbol)
        }
    }

    func append(integer: Int) {
        CLIPSCore.MBAppendInteger(ptr, Int64(integer))
    }

    func append(float: Double) {
        CLIPSCore.MBAppendFloat(ptr, float)
    }

    func append(symbol: String) {
        CLIPSCore.MBAppendSymbol(ptr, symbol)
    }

    func append(string: String) {
        CLIPSCore.MBAppendString(ptr, string)
    }

    func append(instanceName: String) {
        CLIPSCore.MBAppendInstanceName(ptr, instanceName)
    }

    /// Multifields cannot be nested and are inlined when added
    func append(multifield: CLIPSMultifieldPtr) {
        CLIPSCore.MBAppendMultifield(ptr, multifield)
    }

    func append(fact: CLIPSFact) {
        CLIPSCore.MBAppendFact(ptr, fact.ptr)
    }

    func append(instance: CLIPSInstance) {
        CLIPSCore.MBAppendInstance(ptr, instance.ptr)
    }

    func append(externalAddress: CLIPSExternalAddress) {
        CLIPSCore.MBAppendCLIPSExternalAddress(ptr, externalAddress.ptr)
    }

    func append(value: CLIPSValue) {
        value.append(to: self)
    }
}
