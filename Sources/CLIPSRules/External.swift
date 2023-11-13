// Copyright (c) 2023 David N Main

import Foundation
import CLIPSCore


public protocol ExternalAddressFactory {

}

public class ExternalAddressObject {

}

class ExternalAddressType {

    let lexPtr: LexemePtr
    let typeCode: Int32
//    let factory: ExternalAddressFactory

    init(name: String, env: ClipsEnv) { //, factory: ExternalAddressFactory) {
//        self.factory = factory
        lexPtr = CreateSymbol(env, name)!
        RetainLexeme(env, lexPtr)

        var addrType = externalAddressType(name: lexPtr.pointee.contents,
                                           shortPrintFunction: shortPrintFunction(_:_:_:),
                                           longPrintFunction: longPrintFunction(_:_:_:),
                                           discardFunction: discardFunction(_:_:),
                                           newFunction: newFunction(_:_:),
                                           callFunction: callFunction(_:_:_:))

        typeCode = InstallExternalAddressType(env, &addrType)
    }

//    func create() -> ExAddrPtr {
//        CreateExternalAddress(UnsafeMutablePointer<Environment, <#T##UnsafeMutableRawPointer!#>, <#T##UInt16#>)
//    }
}

fileprivate
func newFunction(_ udfContext: UnsafeMutablePointer<UDFContext>?,
                 _ returnValue: UnsafeMutablePointer<UDFValue>?) {

    print("newFunction")

    guard let context = udfContext,
          let retValue = returnValue
    else { return }

    let args = [Value].from(context: context)
    print("args --> \(args)")

    Value.multifield([
        .symbol("Hello"),
        .symbol("World"),
        .multifield([.integer(3), .integer(4)])
    ]).store(in: retValue, env: context.pointee.environment)
}

fileprivate
func callFunction(_ udfContext: UnsafeMutablePointer<UDFContext>?,
                  _ udfValue: UnsafeMutablePointer<UDFValue>?,
                  _ returnValue: UnsafeMutablePointer<UDFValue>?) -> Bool {

    print("callFunction")

    guard let context = udfContext,
          let value = udfValue,
          let retValue = returnValue
    else { return false }

    let val = Value.from(udfValue: value.pointee, env: context.pointee.environment)
    print("val --> \(val)")

    let args = [Value].from(context: context)
    print("args --> \(args)")

    Value.symbol("Hello").store(in: retValue, env: context.pointee.environment)

    return true
}

fileprivate
func shortPrintFunction(_ env: ClipsEnv?,
                        _ name: UnsafePointer<CChar>?,
                        _ addr: UnsafeMutableRawPointer?) {
    guard let name, let addr else { return }
    let logicalName = String(cString: name)

    print("shortPrintFunction \(logicalName)")
}

fileprivate
func longPrintFunction(_ env: ClipsEnv?,
                       _ name: UnsafePointer<CChar>?,
                       _ addr: UnsafeMutableRawPointer?) {
    guard let name, let addr else { return }
    let logicalName = String(cString: name)

    print("longPrintFunction \(logicalName)")
}

fileprivate
func discardFunction(_ env: ClipsEnv?,
                     _ addr: UnsafeMutableRawPointer?) -> Bool {

    print("discardFunction")

    return true
}
