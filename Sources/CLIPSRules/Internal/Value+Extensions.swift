// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation
import CLIPSCore

extension CLIPS {
    typealias TypeHeaderPtr = UnsafeMutablePointer<CLIPSCore.TypeHeader>
    typealias LexemePtr = UnsafeMutablePointer<CLIPSCore.CLIPSLexeme>
    typealias ExternalAddressPtr = UnsafeMutablePointer<CLIPSCore.CLIPSExternalAddress>
    typealias FloatPtr = UnsafeMutablePointer<CLIPSCore.CLIPSFloat>
    typealias IntegerPtr = UnsafeMutablePointer<CLIPSCore.CLIPSInteger>
    typealias VoidPtr = UnsafeMutablePointer<CLIPSCore.CLIPSVoid>
    typealias MultifieldPtr = UnsafeMutablePointer<CLIPSCore.Multifield>
}

extension CLIPS.Value {

    func append(to builder: CLIPS.MFBuilder) {
        switch self {
        case .float(let value): builder.append(float: value)
        case .integer(let value): builder.append(integer: value)
        case .string(let value): builder.append(string: value)
        case .symbol(let value): builder.append(symbol: value)
        case .instanceName(let value): builder.append(instanceName: value)
        case .boolean(let value): builder.append(boolean: value)
        case .fact(let value): builder.append(fact: value)
        case .instance(let value): builder.append(instance: value)
        case .external(let value): builder.append(externalAddress: value)
        case .void: break // void is not a valid element
        case .multifield(let values): // multifields are flattened inline
            for value in values {
                value.append(to: builder)
            }
        }
    }

    func asCLIPSValue(environment: CLIPS.Environment) -> CLIPSCore.CLIPSValue {
        var clipsValue = CLIPSCore.CLIPSValue()
        let env = environment.ptr

        switch self {
        case .float(let value): clipsValue.floatValue = CLIPSCore.CreateFloat(env, value)
        case .integer(let value): clipsValue.integerValue = CLIPSCore.CreateInteger(env, Int64(value))
        case .string(let value): clipsValue.lexemeValue = CLIPSCore.CreateString(env, value)
        case .symbol(let value): clipsValue.lexemeValue = CreateSymbol(env, value)
        case .instanceName(let value): clipsValue.lexemeValue = CLIPSCore.CreateInstanceName(env, value)
        case .boolean(let value): clipsValue.lexemeValue = CLIPSCore.CreateBoolean(env, value)
        case .fact(let value): clipsValue.factValue = value.ptr
        case .instance(let value): clipsValue.instanceValue = value.ptr
        case .external(let value): clipsValue.externalAddressValue = value.ptr
        case .void: clipsValue.voidValue = env.pointee.VoidConstant
        case .multifield(_):
            let builder = CLIPS.MFBuilder(environment: environment)
            self.append(to: builder)
            clipsValue.multifieldValue = builder.createMultifield()
            builder.dispose()
        }

        return clipsValue
    }

    /// Store the value in a UDF value
    func store(in udfValue: CLIPS.UserDefValue, environment: CLIPS.Environment) {
        let env = environment.ptr
        switch self {
        case .float(let value): udfValue.pointee.floatValue = CLIPSCore.CreateFloat(env, value)
        case .integer(let value): udfValue.pointee.integerValue = CLIPSCore.CreateInteger(env, Int64(value))
        case .string(let value): udfValue.pointee.lexemeValue = CLIPSCore.CreateString(env, value)
        case .symbol(let value): udfValue.pointee.lexemeValue = CLIPSCore.CreateSymbol(env, value)
        case .instanceName(let value): udfValue.pointee.lexemeValue = CLIPSCore.CreateInstanceName(env, value)
        case .boolean(let value):
            udfValue.pointee.lexemeValue = value ?
                env.pointee.TrueSymbol :
                env.pointee.FalseSymbol
        case .fact(let value): udfValue.pointee.factValue = value.ptr
        case .instance(let value): udfValue.pointee.instanceValue = value.ptr
        case .external(let value): udfValue.pointee.externalAddressValue = value.ptr
        case .void: udfValue.pointee.voidValue = env.pointee.VoidConstant
        case .multifield(_):
            let builder = CLIPS.MFBuilder(environment: environment)
            self.append(to: builder)
            udfValue.pointee.multifieldValue = builder.createMultifield()
            builder.dispose()
        }
    }

    /// Make a ``Value`` from a CLIPS value
    ///
    /// - Returns: ``.void`` if there is a problem
    static func from(value: CLIPSCore.CLIPSValue, environment: CLIPS.Environment) -> CLIPS.Value {
        func string(from value: CLIPSValue) -> String? {
            value.lexemeValue.pointee.contents.map { String(cString: $0) }
        }

        let env = environment.ptr
        let type = value.header.pointee.type

        switch Int32(type) {
        case FLOAT_TYPE:   return .float(value.floatValue.pointee.contents)
        case INTEGER_TYPE: return .integer(Int(value.integerValue.pointee.contents))
        case VOID_TYPE:    return .void

        case STRING_TYPE:  return string(from: value).map { .string($0) } ?? .void
        case INSTANCE_NAME_TYPE: return string(from: value).map { .instanceName($0) } ?? .void
        case SYMBOL_TYPE:
            if value.lexemeValue == env.pointee.TrueSymbol {
                return .boolean(true)
            } else if value.lexemeValue == env.pointee.FalseSymbol {
                return .boolean(false)
            }
            return string(from: value).map { .symbol($0) } ?? .void

        case FACT_ADDRESS_TYPE: return value.factValue.map { .fact(CLIPS.Fact(ptr: $0)) } ?? .void
        case INSTANCE_ADDRESS_TYPE: return value.instanceValue.map { .instance(CLIPS.Instance(ptr: $0)) } ?? .void
        case EXTERNAL_ADDRESS_TYPE: return value.externalAddressValue.map { .external(CLIPS.ExternalAddress(ptr: $0)) } ?? .void

        case MULTIFIELD_TYPE:
            return value.multifieldValue.map { mf in
                var values: [CLIPS.Value] = []
                let contents = mf.pointer(to: \.contents)
                let buff = UnsafeBufferPointer(start: contents, count: mf.pointee.length)

                for val in buff {
                    let value = Self.from(value: val, environment: environment)
                    values.append(value)
                }

                return .multifield(values)
            } ?? .void

        default: return .void
        }
    }

    /// Make a ``Value`` from a UDF value
    ///
    /// - Returns: ``.void`` if there is a problem
    static func from(udfValue value: CLIPSCore.udfValue, environment: CLIPS.Environment) -> CLIPS.Value {
        func string(from value: udfValue) -> String? {
            value.lexemeValue.pointee.contents.map { String(cString: $0) }
        }

        let type = value.header.pointee.type
        let env = environment.ptr

        switch Int32(type) {
        case FLOAT_TYPE:   return .float(value.floatValue.pointee.contents)
        case INTEGER_TYPE: return .integer(Int(value.integerValue.pointee.contents))
        case VOID_TYPE:    return .void

        case STRING_TYPE:  return string(from: value).map { .string($0) } ?? .void
        case INSTANCE_NAME_TYPE: return string(from: value).map { .instanceName($0) } ?? .void
        case SYMBOL_TYPE:
            if value.lexemeValue == env.pointee.TrueSymbol {
                return .boolean(true)
            } else if value.lexemeValue == env.pointee.FalseSymbol {
                return .boolean(false)
            }
            return string(from: value).map { .symbol($0) } ?? .void

        case FACT_ADDRESS_TYPE: return value.factValue.map { .fact(CLIPS.Fact(ptr: $0)) } ?? .void
        case INSTANCE_ADDRESS_TYPE: return value.instanceValue.map { .instance(CLIPS.Instance(ptr: $0)) } ?? .void
        case EXTERNAL_ADDRESS_TYPE: return value.externalAddressValue.map { .external(CLIPS.ExternalAddress(ptr: $0)) } ?? .void

        case MULTIFIELD_TYPE:
            return value.multifieldValue.map { mf in
                var values: [CLIPS.Value] = []
                let contents = mf.pointer(to: \.contents)
                let buff = UnsafeBufferPointer(start: contents, count: mf.pointee.length)

                for val in buff {
                    let value = Self.from(value: val, environment: environment)
                    values.append(value)
                }

                return .multifield(values)
            } ?? .void

        default: return .void
        }
    }
}
