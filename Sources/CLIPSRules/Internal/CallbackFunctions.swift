//// Copyright (c) 2025 David N Main
//
//import CLIPSCore
//
//fileprivate func clipsFactAssertCallback(_ envPtr: UnsafeMutablePointer<CLIPSCore.Environment>?,
//                                         _ factPtr: UnsafeMutableRawPointer?,
//                                         _ contextPtr: UnsafeMutableRawPointer?) {
//    guard let envPtr,
////          let environment = CLIPS.Engine.from(envPtr)?.environment,
//          let factPtr = factPtr?.assumingMemoryBound(to: CLIPSCore.Fact.self)
//    else { return }
//
//    environment.assertCallback(factPtr: factPtr)
//}
//
//fileprivate func clipsFactRetractCallback(_ envPtr: UnsafeMutablePointer<CLIPSCore.Environment>?,
//                                          _ factPtr: UnsafeMutableRawPointer?,
//                                          _ contextPtr: UnsafeMutableRawPointer?) {
//    guard let envPtr,
//          let environment = CLIPS.Engine.from(envPtr)?.environment,
//          let factPtr = factPtr?.assumingMemoryBound(to: CLIPSCore.Fact.self)
//    else { return }
//
//    environment.retractCallback(factPtr: factPtr)
//}
//
//fileprivate func clipsFactModifyCallback(_ envPtr: UnsafeMutablePointer<CLIPSCore.Environment>?,
//                                         _ oldFactPtr: UnsafeMutablePointer<CLIPSCore.Fact>?,
//                                         _ newFactPtr: UnsafeMutablePointer<CLIPSCore.Fact>?,
//                                         _ contextPtr: UnsafeMutableRawPointer?) {
//    guard let envPtr,
//          let environment = CLIPS.Engine.from(envPtr)?.environment
//    else { return }
//
//    environment.modifyCallback(oldFactPtr: oldFactPtr, newFactPtr: newFactPtr)
//}
//
//extension CLIPS.Fact {
//
//    /// Get the `CLIPS.Environment.FactInstance` associated with the fact, if any
//    public var factInstance: CLIPS.Environment.FactInstance? {
//        guard let swiftFactPtr = ptr.pointee.swiftFact,
//              let instancePtr = swiftFactPtr.pointee.instance
//            else { return nil }
//
//        return Unmanaged.fromOpaque(instancePtr).takeUnretainedValue()
//    }
//}
//
//extension CLIPS.Environment {
//
//    public class FactInstance {
//        let fact: Fact
//        init(fact: Fact) {
//            self.fact = fact
//        }
//
//        deinit {
//            #if DEBUG
//            CLIPS.logger.debug("♻️ FactInstance deinitialized")
//            #endif
//        }
//    }
//
//    public class FactInstanceFactory {
//        let template: CLIPS.FactTemplate
//
//        /// Attach this new instance to the given template (which owns a reference)
//        init(template: CLIPS.FactTemplate) {
//            self.template = template
//
//            #if DEBUG
//            template.ptr.pointee.swiftTemplate = .allocate(capacity: 1)
//            CLIPS.logger.debug("🔅 FactInstanceFactory initialized")
//            #endif
//        }
//
//        deinit {
//            #if DEBUG
//            CLIPS.logger.debug("♻️ FactInstanceFactory deinitialized")
//            #endif
//        }
//    }
//
//    func registerFactCallbacks() {
//        let assertNamePtr = retainCStringPtr(from: "assertCallback")
//        let retractNamePtr = retainCStringPtr(from: "retractCallback")
//        let modifyNamePtr = retainCStringPtr(from: "modifyCallback")
//        CLIPSCore.AddAssertFunction(ptr, assertNamePtr, clipsFactAssertCallback, 0, nil)
//        CLIPSCore.AddRetractFunction(ptr, retractNamePtr, clipsFactRetractCallback, 0, nil)
//        CLIPSCore.AddModifyFunction(ptr, modifyNamePtr, clipsFactModifyCallback, 0, nil)
//    }
//
//    func assertCallback(factPtr: UnsafeMutablePointer<CLIPSCore.Fact>) {
//        if let name = factPtr.pointee.whichDeftemplate.pointee.header.name.pointee.contents {
//            let nameString = String(cString: name)
//            print("clipsFactAssertCallback -- \(nameString)")
//        }
//    }
//
//    func retractCallback(factPtr: UnsafeMutablePointer<CLIPSCore.Fact>) {
//        if let name = factPtr.pointee.whichDeftemplate.pointee.header.name.pointee.contents {
//            let nameString = String(cString: name)
//            print("clipsFactRetractCallback -- \(nameString)")
//        }
//    }
//
//    func modifyCallback(oldFactPtr: UnsafeMutablePointer<CLIPSCore.Fact>?,
//                        newFactPtr: UnsafeMutablePointer<CLIPSCore.Fact>?) {
//        if let name = factPtr.pointee.whichDeftemplate.pointee.header.name.pointee.contents {
//            let nameString = String(cString: name)
//            print("clipsFactModifyCallback -- \(nameString)")
//        }
//    }
//}
