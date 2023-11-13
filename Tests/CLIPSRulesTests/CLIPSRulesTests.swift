// Copyright (c) 2023 David N Main

import XCTest
@testable import CLIPSRules

final class CLIPSRulesTests: CLIPSTestBase {
    func testSanity() throws {
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

    func testFunctionCall() throws {
        try clips.load(path: try pathFor(sample: "test1"))
        let result = try clips.call("foo", .integer(2), .integer(3), .string("Hello World"))
        XCTAssertEqual(result, .integer(5))

        let result2 = try clips.call("assert-bar",
                                     .symbol("hello"),
                                     .symbol("world"))

        if case let .fact(fact) = result2 {
            XCTAssertTrue(clips.factExists(fact))
        } else {
            XCTFail("result was not a fact")
        }
    }

    func testExternalAddress() throws {
        class Foo {
            static var count = 0
            init() { Self.count += 1 }
            deinit { Self.count -= 1 }
        }

        XCTAssertEqual(Foo.count, 0)
        var extAddr = clips.createExternalAddress(Foo())
        XCTAssertEqual(Foo.count, 1)
        clips.gc()
        XCTAssertEqual(Foo.count, 0) // Foo was deinited by gc

        let foo = Foo()
        extAddr = clips.createExternalAddress(foo)
        XCTAssertEqual(Foo.count, 1)
        clips.gc()
        XCTAssertEqual(Foo.count, 1) // Foo was not release by gc

        let foo2 = Foo()
        extAddr = clips.createExternalAddress(foo2)
        if let foo3 = clips.object(from: extAddr) as? Foo {
            XCTAssertTrue(foo3 === foo2)
        } else {
            XCTFail("Ext Addr object not retrieved")
        }
    }
}
