// Copyright (c) 2023 David N Main

import Foundation
import Testing
@testable import CLIPSRules

final class CLIPSRules: CLIPSTest {

    @Test
    func sanity() async throws {
        await clips.watch(for: .rules, enabled: true)
        await clips.addLogicalIO(name: "zebra")
        await clips.printBanner()
        try await clips.load(path: try pathFor(sample: "zebra"))
        await clips.reset()
        await clips.run()

        let result = try await clips.eval("(create$ 1 2 a \"b\")")
        print(result ?? .void)

        try await clips.build("""
        (defrule print-foobar
            (foobar ?a ?b ?c)
            =>
            (println "The rule ran!!")
            (println ?a " - " ?b " - " ?c))
        """)

        try await clips.assert(fact: "(foobar 1 2 3)")
        await clips.run()
    }

    @Test
    func functionCall() async throws {
        try await clips.load(path: try pathFor(sample: "test1"))
        let result = try await clips.call("foo", .integer(2), .integer(3), .string("Hello World"))
        #expect(result == .integer(5))

        let result2 = try await clips.call("assert-bar",
                                           .symbol("hello"),
                                           .symbol("world"))

        if case let .fact(fact) = result2 {
            #expect(fact.isAsserted)
        } else {
            Issue.record("result was not a fact")
        }
    }

    @Test
    func externalAddress() async throws {
        class Foo {
            static var count = 0
            init() { Self.count += 1 }
            deinit { Self.count -= 1 }
        }

        #expect(Foo.count == 0)
        var strongFoo: Foo? = Foo()
        weak var weakFoo = strongFoo
        var extAddr: CLIPSExternalAddress? = await clips.createExternalAddress(weakFoo!)
        strongFoo = nil
        #expect(Foo.count == 1)
        #expect(weakFoo != nil)
        await clips.gc()
        #expect(Foo.count == 1)
        #expect(weakFoo != nil)
        extAddr = nil
        try await Task.sleep(nanoseconds: 100_000)
        await clips.gc()
        #expect(Foo.count == 0) // Foo was deinited by gc
        #expect(weakFoo == nil)

        strongFoo = Foo()
        extAddr = await clips.createExternalAddress(strongFoo!)
        #expect(Foo.count == 1)
        try await Task.sleep(nanoseconds: 100_000)
        await clips.gc()
        #expect(Foo.count == 1) // Foo was not released by gc

        // object(from:) gets same object and has a retain
        extAddr = nil
        try await Task.sleep(nanoseconds: 100_000)
        await clips.gc()
        strongFoo = Foo()
        weakFoo = strongFoo
        #expect(Foo.count == 1)
        extAddr = await clips.createExternalAddress(strongFoo!)

        var strongFoo2: Foo? = await clips.object(from: extAddr!) as? Foo
        weak var weakFoo2 = strongFoo2
        #expect(Foo.count == 1)
        #expect(strongFoo2 != nil)
        #expect(strongFoo2 === strongFoo)

        // release extAddr and strongFoo - strongFoo2 should still retain
        extAddr = nil
        try await Task.sleep(nanoseconds: 100_000)
        await clips.gc()
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
