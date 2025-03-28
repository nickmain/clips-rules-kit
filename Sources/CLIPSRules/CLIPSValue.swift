// Copyright (c) 2025 David N Main

import CLIPSCore

/// A value of the one of the various kinds that CLIPS supports
public enum CLIPSValue: Equatable {
    case float(Double)
    case integer(Int)
    case string(String)
    case symbol(String)
    case instanceName(String)
    case boolean(Bool)
    case fact(CLIPSFact)
    case instance(CLIPSInstance)
    case external(CLIPSExternalAddress)
    case multifield([CLIPSValue])
    case void

    var asString: String {
        switch self {
        case .float(let value): "\(value)"
        case .integer(let value): "\(value)"
        case .string(let value): value
        case .symbol(let value): value
        case .instanceName(let value): value
        case .boolean(let value): "\(value)"
        case .fact(let value): "fact-\(value.index)"
        case .instance(let value): "instance[\(value.name)]"
        case .external: "<external-address>"
        case .multifield(let values): values.map { $0.asString }.joined(separator: ", ")
        case .void: "void"
        }
    }

    func asCLIPSValue(pEnv: CLIPSEnvironment.Ptr) -> CLIPSCore.CLIPSValue {
        var clipsValue = CLIPSCore.CLIPSValue()

        switch self {
        case .float(let value): clipsValue.floatValue = CLIPSCore.CreateFloat(pEnv, value)
        case .integer(let value): clipsValue.integerValue = CLIPSCore.CreateInteger(pEnv, Int64(value))
        case .string(let value): clipsValue.lexemeValue = CLIPSCore.CreateString(pEnv, value)
        case .symbol(let value): clipsValue.lexemeValue = CreateSymbol(pEnv, value)
        case .instanceName(let value): clipsValue.lexemeValue = CLIPSCore.CreateInstanceName(pEnv, value)
        case .boolean(let value): clipsValue.lexemeValue = CLIPSCore.CreateBoolean(pEnv, value)
        case .fact(let value): clipsValue.factValue = value.ptr
        case .instance(let value): clipsValue.instanceValue = value.ptr
        case .external(let value): clipsValue.externalAddressValue = value.ptr
        case .void: clipsValue.voidValue = pEnv.pointee.VoidConstant
        case .multifield(_):
            let builder = CLIPSMFBuilder(pEnv: pEnv)
            self.append(to: builder)
            clipsValue.multifieldValue = builder.createMultifield()
            builder.dispose()
        }

        return clipsValue
    }

    func append(to builder: CLIPSMFBuilder) {
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

    static func from(value: CLIPSCore.CLIPSValue, env: CLIPSEnvironment, pEnv: CLIPSEnvironment.Ptr) -> CLIPSValue {
        func string(from value: CLIPSCore.CLIPSValue) -> String? {
            value.lexemeValue.pointee.contents.map { String(cString: $0) }
        }

        let type = value.header.pointee.type

        switch Int32(type) {
        case FLOAT_TYPE:   return .float(value.floatValue.pointee.contents)
        case INTEGER_TYPE: return .integer(Int(value.integerValue.pointee.contents))
        case VOID_TYPE:    return .void

        case STRING_TYPE:  return string(from: value).map { .string($0) } ?? .void
        case INSTANCE_NAME_TYPE: return string(from: value).map { .instanceName($0) } ?? .void
        case SYMBOL_TYPE:
            if value.lexemeValue == pEnv.pointee.TrueSymbol {
                return .boolean(true)
            } else if value.lexemeValue == pEnv.pointee.FalseSymbol {
                return .boolean(false)
            }
            return string(from: value).map { .symbol($0) } ?? .void

        case FACT_ADDRESS_TYPE: return value.factValue.map { .fact(CLIPSFact(ptr: $0, env: env)) } ?? .void
        case INSTANCE_ADDRESS_TYPE: return value.instanceValue.map { .instance(CLIPSInstance(ptr: $0, env: env)) } ?? .void
        case EXTERNAL_ADDRESS_TYPE: return value.externalAddressValue.map { .external(CLIPSExternalAddress(ptr: $0, env: env)) } ?? .void

        case MULTIFIELD_TYPE:
            return value.multifieldValue.map { mf in
                var values: [CLIPSValue] = []
                let contents = mf.pointer(to: \.contents)
                let buff = UnsafeBufferPointer(start: contents, count: mf.pointee.length)

                for val in buff {
                    let value = Self.from(value: val, env: env, pEnv: pEnv)
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
    static func from(udfValue value: CLIPSCore.udfValue,  env: CLIPSEnvironment, pEnv: CLIPSEnvironment.Ptr) -> CLIPSValue {
        func string(from value: udfValue) -> String? {
            value.lexemeValue.pointee.contents.map { String(cString: $0) }
        }

        let type = value.header.pointee.type

        switch Int32(type) {
        case FLOAT_TYPE:   return .float(value.floatValue.pointee.contents)
        case INTEGER_TYPE: return .integer(Int(value.integerValue.pointee.contents))
        case VOID_TYPE:    return .void

        case STRING_TYPE:  return string(from: value).map { .string($0) } ?? .void
        case INSTANCE_NAME_TYPE: return string(from: value).map { .instanceName($0) } ?? .void
        case SYMBOL_TYPE:
            if value.lexemeValue == pEnv.pointee.TrueSymbol {
                return .boolean(true)
            } else if value.lexemeValue == pEnv.pointee.FalseSymbol {
                return .boolean(false)
            }
            return string(from: value).map { .symbol($0) } ?? .void

        case FACT_ADDRESS_TYPE: return value.factValue.map { .fact(CLIPSFact(ptr: $0, env: env)) } ?? .void
        case INSTANCE_ADDRESS_TYPE: return value.instanceValue.map { .instance(CLIPSInstance(ptr: $0, env: env)) } ?? .void
        case EXTERNAL_ADDRESS_TYPE: return value.externalAddressValue.map { .external(CLIPSExternalAddress(ptr: $0, env: env)) } ?? .void

        case MULTIFIELD_TYPE:
            return value.multifieldValue.map { mf in
                var values: [CLIPSValue] = []
                let contents = mf.pointer(to: \.contents)
                let buff = UnsafeBufferPointer(start: contents, count: mf.pointee.length)

                for val in buff {
                    let value = Self.from(value: val, env: env, pEnv: pEnv)
                    values.append(value)
                }

                return .multifield(values)
            } ?? .void

        default: return .void
        }
    }

    /// Store the value in a UDF value
    func store(in udfValue: CLIPSUDFValuePtr, env: CLIPSEnvironment, pEnv: CLIPSEnvironment.Ptr) {
        switch self {
        case .float(let value): udfValue.pointee.floatValue = CLIPSCore.CreateFloat(pEnv, value)
        case .integer(let value): udfValue.pointee.integerValue = CLIPSCore.CreateInteger(pEnv, Int64(value))
        case .string(let value): udfValue.pointee.lexemeValue = CLIPSCore.CreateString(pEnv, value)
        case .symbol(let value): udfValue.pointee.lexemeValue = CLIPSCore.CreateSymbol(pEnv, value)
        case .instanceName(let value): udfValue.pointee.lexemeValue = CLIPSCore.CreateInstanceName(pEnv, value)
        case .boolean(let value):
            udfValue.pointee.lexemeValue = value ?
            pEnv.pointee.TrueSymbol :
            pEnv.pointee.FalseSymbol
        case .fact(let value): udfValue.pointee.factValue = value.ptr
        case .instance(let value): udfValue.pointee.instanceValue = value.ptr
        case .external(let value): udfValue.pointee.externalAddressValue = value.ptr
        case .void: udfValue.pointee.voidValue = pEnv.pointee.VoidConstant
        case .multifield(_):
            let builder = CLIPSMFBuilder(pEnv: pEnv)
            self.append(to: builder)
            udfValue.pointee.multifieldValue = builder.createMultifield()
            builder.dispose()
        }
    }
}
