// Copyright (c) 2024 David N Main

import Testing
@testable import CLIPSCore
@testable import CLIPSRules

final class TemplatePeerTests: CLIPSTest {

    class FactPeer {
        init(factPtr: UnsafeMutablePointer<Fact>) {
            func handleAssert(_ factPtr: UnsafeMutablePointer<Fact>?) {
                print("FactPeer handleAssert")
            }

            func handleRetract(_ factPtr: UnsafeMutablePointer<Fact>?) {

            }

            func handleRelease(_ factPtr: UnsafeMutablePointer<Fact>?) {
                guard let factPtr,
                      let swiftFactPtr = factPtr.pointee.swiftFact,
                      let instancePtr = swiftFactPtr.pointee.instance
                else { return }

                factPtr.pointee.swiftFact = nil
                Unmanaged<FactPeer>.fromOpaque(instancePtr).release()
                swiftFactPtr.deallocate()
            }

            let swiftFact = UnsafeMutablePointer<CLIPSCore.SwiftFact>.allocate(capacity: 1)
            let factPeerPtr = Unmanaged.passRetained(self).toOpaque()
            swiftFact.pointee.instance = factPeerPtr
            swiftFact.pointee.handleAssert = handleAssert
            swiftFact.pointee.handleRetract = handleRetract
            swiftFact.pointee.handleRelease = handleRelease

            factPtr.pointee.swiftFact = swiftFact
        }

        deinit {
            print("FactPeer deinitialized")
        }
    }

    @Test func sanity() async throws {
        try clips.build("(deftemplate foo (slot a) (slot b))")
        let template = clips.findFactTemplate(named: "foo")
        #expect(template != nil)
        #expect(template?.ptr.pointee.swiftTemplate == nil)

        class Instance {
            var message: String = "Hello, world!"
            var facts = [FactPeer]()

            deinit {
                print("Instance deinitialized")
            }
        }
        var strongInstance: Instance? = Instance()
        weak var weakInstance = strongInstance
        let instancePtr = Unmanaged.passRetained(strongInstance!).toOpaque()
        strongInstance = nil
        #expect(weakInstance != nil)

        func newFactHandler(_ templatePtr: UnsafeMutablePointer<CLIPSCore.SwiftTemplate>?,
                            _ factPtr: UnsafeMutablePointer<CLIPSCore.Fact>?) {
            guard let templatePtr,
                  let factPtr,
                  let instancePtr = templatePtr.pointee.instance
            else { return }

            let instance = Unmanaged<Instance>.fromOpaque(instancePtr).takeUnretainedValue()
            instance.facts.append(FactPeer(factPtr: factPtr))

            print("👋 newFactHandler \(instance.message)")
        }

        func releaseHandler(_ templatePtr: UnsafeMutablePointer<CLIPSCore.Deftemplate>?) {
            guard let templatePtr,
                  let swiftTemplatePtr = templatePtr.pointee.swiftTemplate,
                  let instancePtr = swiftTemplatePtr.pointee.instance
            else { return }

            print("👋 releaseHandler")

            templatePtr.pointee.swiftTemplate = nil
            Unmanaged<Instance>.fromOpaque(instancePtr).release()
            swiftTemplatePtr.deallocate()
        }

        let swiftTemplate = UnsafeMutablePointer<CLIPSCore.SwiftTemplate>.allocate(capacity: 1)
        swiftTemplate.pointee.instance = instancePtr
        swiftTemplate.pointee.swiftNewFactHandler = newFactHandler
        swiftTemplate.pointee.handleTemplateRelease = releaseHandler
        template?.ptr.pointee.swiftTemplate = swiftTemplate

        #expect(weakInstance?.message == "Hello, world!")
        try clips.assert(fact: "(foo (a 1) (b 2))")

        #expect(weakInstance != nil)
        engine = CLIPS.Engine() // release existing engine
        #expect(weakInstance == nil)
    }
}
