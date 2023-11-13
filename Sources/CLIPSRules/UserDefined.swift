// Copyright (c) 2023 David N Main - All Rights Reserved.

import Foundation
import CLIPSCore

public typealias UserDefValue = UnsafeMutablePointer<UDFValue>
public typealias UserDefContext = UnsafeMutablePointer<UDFContext>

public extension Value {
    /// Store the value in a UDF value
    func store(in udfValue: UserDefValue, env: ClipsEnv) {
        switch self {
        case .float(let value): udfValue.pointee.floatValue = CreateFloat(env, value)
        case .integer(let value): udfValue.pointee.integerValue = CreateInteger(env, value)
        case .string(let value): udfValue.pointee.lexemeValue = CreateString(env, value)
        case .symbol(let value): udfValue.pointee.lexemeValue = CreateSymbol(env, value)
        case .instanceName(let value): udfValue.pointee.lexemeValue = CreateInstanceName(env, value)
        case .boolean(let value):
            udfValue.pointee.lexemeValue = value ?
                env.pointee.TrueSymbol :
                env.pointee.FalseSymbol
        case .fact(let ptr): udfValue.pointee.factValue = ptr
        case .instance(let ptr): udfValue.pointee.instanceValue = ptr
        case .external(let ptr): udfValue.pointee.externalAddressValue = ptr
        case .multifield(let values):
            udfValue.pointee.multifieldValue = values.toMultifield(env: env)
        case .void: udfValue.pointee.voidValue = env.pointee.VoidConstant
        }
    }

    /// Get ``Value`` from a UDFValue
    static func from(udfValue value: udfValue, env: ClipsEnv) -> Value? {
        func string(from value: udfValue) -> String? {
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

public extension Array where Element == Value {
    /// Get argument values from a UDF context
    static func from(context: UserDefContext) -> [Value] {
        guard let env = context.pointee.environment else { return [] }
        var values: [Value] = []
        var value = UDFValue()

        while context.pointee.lastArg != nil {
            if UDFNextArgument(context, 0b11111111111, &value) {
                if let value = Value.from(udfValue: value, env: env) {
                    values.append(value)
                }
            }
        }

        return values
    }

    /// Create a multifield from an array of values
    func toMultifield(env: ClipsEnv) -> UnsafeMutablePointer<multifield>? {
        let builder = CreateMultifieldBuilder(env, self.count)

        for value in self {
            switch value {
            case .float(let value): MBAppendFloat(builder, value)
            case .integer(let value): MBAppendInteger(builder, value)
            case .string(let s): MBAppendString(builder, s)
            case .symbol(let s): MBAppendSymbol(builder, s)
            case .instanceName(let s): MBAppendInstanceName(builder, s)
            case .boolean(let value):
                MBAppendCLIPSLexeme(builder,
                                    value ? env.pointee.TrueSymbol :
                                            env.pointee.FalseSymbol)
            case .fact(let ptr): MBAppendFact(builder, ptr)
            case .instance(let ptr): MBAppendInstance(builder, ptr)
            case .external(let ptr): MBAppendCLIPSExternalAddress(builder, ptr)
            case .multifield(let values):
                MBAppendMultifield(builder, values.toMultifield(env: env))
            case .void: MBAppendInteger(builder, 0)
            }
        }

        let mf = MBCreate(builder)
        MBDispose(builder)
        return mf
    }
}
