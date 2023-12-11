// Copyright (c) 2023 David N Main

import XCTest
@testable import CLIPSRules

final class CLIPSRulesTests: CLIPSTestBase {
    func testExample() async throws {
        await Watch.rules.set(on: true, for: clips)
        await clips.addLogicalIO(name: "zebra")
        await clips.printBanner()
        await clips.load(path: try pathFor(sample: "zebra"))
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

    func testExternalCall() async throws {
        print(try await clips.eval("(call swift foo 34 TRUE)") ?? .string("???"))
        print(try await clips.eval("(new swift foo 34 TRUE)") ?? .string("???"))
    }
}
