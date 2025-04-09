// Copyright (c) 2025 David N Main

import CLIPSCore

public struct CLIPSClass {
    typealias Ptr = UnsafeMutablePointer<CLIPSCore.Defclass>

    let ptr: Ptr
    private let env: CLIPSEnvironment

    public var module: String { String(cString: CLIPSCore.DefclassModule(ptr)) }
    public var name: String { String(cString: CLIPSCore.DefclassName(ptr)) }
    public var prettyPrint: String {
        guard let pChar = CLIPSCore.DefclassPPForm(ptr) else { return "template \(name)" }
        return String(cString: pChar)
    }

    init(ptr: Ptr, env: CLIPSEnvironment) {
        self.ptr = ptr
        self.env = env
    }

    public func getFirstInstance() async -> CLIPSInstance? {
        await env.withPtr { pEnv in
            guard let firstPtr = CLIPSCore.GetNextInstanceInClass(ptr, nil) else { return nil }
            return CLIPSInstance(ptr: firstPtr, env: env)
        }
    }

    public func getNextInstance(after instance: CLIPSInstance) async -> CLIPSInstance? {
        await env.withPtr { pEnv in
            guard let pInstance = CLIPSCore.GetNextInstanceInClass(ptr, instance.ptr) else { return nil }
            return CLIPSInstance(ptr: pInstance, env: env)
        }
    }

    public func getNextClass() async -> CLIPSClass? {
        await env.withPtr { pEnv in
            guard let nextPtr = CLIPSCore.GetNextDefclass(pEnv, ptr) else { return nil }
            return CLIPSClass(ptr: nextPtr, env: env)
        }
    }

    public func getSlotNames(includeInherited: Bool = false) async -> [String] {
        return await env.withPtr { pEnv in
            var value = CLIPSCore.CLIPSValue()
            CLIPSCore.ClassSlots(ptr, &value, includeInherited)
            let names = CLIPSValue.from(value: value,env: env,  pEnv: pEnv)
            return switch names {
            case .multifield(let values):
                values.map { $0.asString }
            default:
                []
            }
        }
    }

    public func getSuperclassNames(includeInherited: Bool = false) async -> [String] {
        return await env.withPtr { pEnv in
            var value = CLIPSCore.CLIPSValue()
            CLIPSCore.ClassSuperclasses(ptr, &value, includeInherited)
            let names = CLIPSValue.from(value: value, env: env, pEnv: pEnv)
            return switch names {
            case .multifield(let values):
                values.map { $0.asString }
            default:
                []
            }
        }
    }

    public func getSubclassNames(includeInherited: Bool = false) async -> [String] {
        return await env.withPtr { pEnv in
            var value = CLIPSCore.CLIPSValue()
            CLIPSCore.ClassSubclasses(ptr, &value, includeInherited)
            let names = CLIPSValue.from(value: value, env: env, pEnv: pEnv)
            return switch names {
            case .multifield(let values):
                values.map { $0.asString }
            default:
                []
            }
        }
    }
}
