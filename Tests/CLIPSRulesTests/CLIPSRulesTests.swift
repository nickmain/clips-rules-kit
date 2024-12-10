// Copyright (c) 2023 David N Main

import Foundation
import Testing
@testable import CLIPSRules

final class CLIPSRules: CLIPSTest {

    @Test
    func sanity() throws {
        clips.watch(for: .rules, enabled: true)
        clips.addLogicalIO(name: "zebra")
        clips.printBanner()
        try clips.load(path: try pathFor(sample: "zebra"))
        clips.reset()
        clips.run()

        let result = try clips.eval("(create$ 1 2 a \"b\")")
        print(result ?? .void)

        try clips.build("""
        (defrule print-foobar
            (foobar ?a ?b ?c)
            =>
            (println "The rule ran!!")
            (println ?a " - " ?b " - " ?c))
        """)

        try clips.assert(fact: "(foobar 1 2 3)")
        clips.run()
    }

    @Test
    func functionCall() throws {
        try clips.load(path: try pathFor(sample: "test1"))
        let result = try clips.call("foo", .integer(2), .integer(3), .string("Hello World"))
        #expect(result == .integer(5))

        let result2 = try clips.call("assert-bar",
                                     .symbol("hello"),
                                     .symbol("world"))

        if case let .fact(fact) = result2 {
            #expect(clips.factExists(fact))
        } else {
            Issue.record("result was not a fact")
        }
    }

    @Test
    func externalAddress() throws {
        class Foo {
            static var count = 0
            init() { Self.count += 1 }
            deinit { Self.count -= 1 }
        }

        #expect(Foo.count == 0)
        var strongFoo: Foo? = Foo()
        weak var weakFoo = strongFoo
        var extAddr = clips.createExternalAddress(weakFoo!)
        strongFoo = nil
        #expect(Foo.count == 1)
        #expect(weakFoo != nil)
        clips.retain(extAddr)
        clips.gc()
        #expect(Foo.count == 1)
        #expect(weakFoo != nil)
        clips.release(extAddr)
        clips.gc()
        #expect(Foo.count == 0) // Foo was deinited by gc
        #expect(weakFoo == nil)

        strongFoo = Foo()
        extAddr = clips.createExternalAddress(strongFoo!)
        #expect(Foo.count == 1)
        clips.gc()
        #expect(Foo.count == 1) // Foo was not released by gc

        // object(from:) gets same object and has a retain
        strongFoo = Foo()
        weakFoo = strongFoo
        #expect(Foo.count == 1)
        extAddr = clips.createExternalAddress(strongFoo!)

        var strongFoo2: Foo? = clips.object(from: extAddr) as? Foo
        weak var weakFoo2 = strongFoo2
        #expect(Foo.count == 1)
        #expect(strongFoo2 != nil)
        #expect(strongFoo2 === strongFoo)

        // release extAddr and strongFoo - strongFoo2 should still retain
        clips.gc()
        strongFoo = nil
        #expect(weakFoo != nil)
        #expect(weakFoo2 != nil)
        #expect(Foo.count == 1)

        strongFoo2 = nil
        #expect(weakFoo == nil)
        #expect(weakFoo2 == nil)
        #expect(Foo.count == 0)
    }
}
