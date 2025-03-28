// Copyright (c) 2025 David N Main

import CLIPSCore

public struct CLIPSTemplate: Equatable {

    typealias Ptr = UnsafeMutablePointer<CLIPSCore.Deftemplate>

    public static func == (lhs: CLIPSTemplate, rhs: CLIPSTemplate) -> Bool {
        lhs.ptr == rhs.ptr
    }

    /// The slot name for an ordered fact
    public static let IMPLIED_SLOT_NAME = "implied"

    let ptr: Ptr
    private let env: CLIPSEnvironment

    public var module: String { String(cString: CLIPSCore.DeftemplateModule(ptr)) }
    public var name: String { String(cString: CLIPSCore.DeftemplateName(ptr)) }
    public var prettyPrint: String {
        guard let pChar = CLIPSCore.DeftemplatePPForm(ptr) else { return "template \(name)" }
        return String(cString: pChar)
    }
    public var watchFacts: Bool {
        get { CLIPSCore.DeftemplateGetWatch(ptr) }
        set { CLIPSCore.DeftemplateSetWatch(ptr, newValue) }
    }

    init(ptr: Ptr, env: CLIPSEnvironment) {
        self.ptr = ptr
        self.env = env
    }

    public func getNextTemplate() async -> CLIPSTemplate? {
        return await env.withPtr { pEnv in
            guard let ptr = CLIPSCore.GetNextDeftemplate(pEnv, ptr) else { return nil }
            return .init(ptr: ptr, env: env)
        }
    }

    public func getSlotNames() async -> [String] {
        return await env.withPtr { pEnv in
            var value = CLIPSCore.CLIPSValue()
            CLIPSCore.DeftemplateSlotNames(ptr, &value)
            let names = CLIPSValue.from(value: value, env: env, pEnv: pEnv)
            return switch names {
            case .multifield(let values):
                values.map { $0.asString }
            default:
                []
            }
        }
    }

    /// Get the first fact that belongs to this template
    public func getFirstFact() async -> CLIPSFact? {
        return await env.withPtr { pEnv in
            guard let ptr = CLIPSCore.GetNextFactInTemplate(ptr, nil) else { return nil }
            return .init(ptr: ptr, env: env)
        }
    }

    /// Get the next fact that belongs to this template
    public func getNextFact(after fact: CLIPSFact) async -> CLIPSFact? {
        return await env.withPtr { pEnv in
            guard let ptr = CLIPSCore.GetNextFactInTemplate(ptr, fact.ptr) else { return nil }
            return .init(ptr: ptr, env: env)
        }
    }
}
