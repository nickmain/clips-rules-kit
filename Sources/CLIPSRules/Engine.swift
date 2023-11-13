// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import Foundation
import CLIPSCore

extension CLIPS {

    /// The CLIPS engine
    public class Engine {

        /// The CLIPS environment
        public let environment: Environment

        // strong references to the UDF handlers
        private let udfHandlers = UDFHandlerRefs()
        private class UDFHandlerRefs {
            fileprivate var refs = [UserDefinedFunctionHandlerReference]()
        }
        internal func addUDFHandler(_ ref: UserDefinedFunctionHandlerReference) {
            udfHandlers.refs.append(ref)
        }

        internal static func from(_ env: EnvironmentPtr) -> Engine? {
            guard let context = env.pointee.context else { return nil }
            return Unmanaged.fromOpaque(context).takeUnretainedValue()
        }

        /// Create an instance of the CLIPS engine.
        ///
        /// - Parameter handler: optional handler for output lines.
        ///                      Defaults to an implementation that prints to the ``CLIPS/defaultOutputLogger``.
        ///
        public init(handler: CLIPSOutputHandler? = nil) {
            let router = Router(handler: handler ?? DefaultHandler())
            let env: EnvironmentPtr = CLIPSCore.CreateEnvironment()

            #if DEBUG
            let ptr = env
            CLIPS.logger.debug("🔆 CLIPS: CreateEnvironment \(String(describing: ptr))")
            #endif

            router.addStdOut()
            router.addStdErr()
            router.addStdWrn()
            router.addRouter(env: env)

            // install "swift" enternal address type
            let lexPtr = CLIPSCore.CreateSymbol(env, "swift")!
            CLIPSCore.RetainLexeme(env, lexPtr)
            var addrType = CLIPSCore.externalAddressType(
                               name: lexPtr.pointee.contents,
                               shortPrintFunction: nil,
                               longPrintFunction: nil,
                               discardFunction: discardFunction(_:_:),
                               newFunction: nil,
                               callFunction: nil)

            let code = Int(CLIPSCore.InstallExternalAddressType(env, &addrType))

            environment = Environment(ptr: env, extAddrTypeCode: code, router: router)

            env.pointee.context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        }

        deinit {
            let env = environment.ptr

            // attempt to force a gc
            var value = CLIPSCore.CLIPSValue()
            _ = CLIPSCore.Eval(env, "true", &value)

            #if DEBUG
            let ptr = env
            CLIPS.logger.debug("♻️ CLIPS: DestroyEnvironment \(String(describing: ptr))")
            #endif

            env.pointee.context = nil
            CLIPSCore.DestroyEnvironment(env)
        }
    }
}
