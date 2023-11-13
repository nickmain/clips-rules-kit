// Copyright (c) 2023 David N Main - All Rights Reserved.

import Foundation
import CLIPSCore

public typealias FactPtr = UnsafeMutablePointer<Fact>
public typealias InstancePtr = UnsafeMutablePointer<Instance>
public typealias LexemePtr = UnsafeMutablePointer<CLIPSLexeme>
public typealias ExAddrPtr = UnsafeMutablePointer<CLIPSExternalAddress>

/// A CLIPS primitive value
public enum Value {
    case float(Double)
    case integer(Int64)
    case string(String)
    case symbol(String)
    case instanceName(String)
    case boolean(Bool)
    case fact(FactPtr)
    case instance(InstancePtr)
    case external(ExAddrPtr)
    case multifield([Value])
    case void
}

public extension Value {
    /// Make a ``Value`` from a CLIPS value
    static func from(value: CLIPSValue, env: ClipsEnv) -> Value? {
        func string(from value: CLIPSValue) -> String? {
            value.lexemeValue.pointee.contents.map { String(cString: $0) }
        }

        let type = value.header.pointee.type

        switch Int32(type) {
        case FLOAT_TYPE:   return .float(value.floatValue.pointee.contents)
        case INTEGER_TYPE: return .integer(value.integerValue.pointee.contents)
        case VOID_TYPE:    return .void

        case STRING_TYPE:        return string(from: value).map { .string($0) }
        case INSTANCE_NAME_TYPE: return string(from: value).map { .instanceName($0) }
        case SYMBOL_TYPE:
            if value.lexemeValue == env.pointee.TrueSymbol {
                return .boolean(true)
            } else if value.lexemeValue == env.pointee.FalseSymbol {
                return .boolean(false)
            }
            return string(from: value).map { .symbol($0) }

        case FACT_ADDRESS_TYPE: return value.factValue.map { .fact($0) }
        case INSTANCE_ADDRESS_TYPE: return value.instanceValue.map { .instance($0) }
        case EXTERNAL_ADDRESS_TYPE: return value.externalAddressValue.map { .external($0) }

        case MULTIFIELD_TYPE:
            return value.multifieldValue.map { mf in
                var values: [Value] = []
                let contents = mf.pointer(to: \.contents)
                let buff = UnsafeBufferPointer(start: contents, count: mf.pointee.length)

                for val in buff {
                    if let value = Self.from(value: val, env: env) {
                        values.append(value)
                    }
                }

                return .multifield(values)
            }

        default: return nil
        }
    }
}

