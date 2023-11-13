import XCTest
@testable import CLIPSRules

final class CLIPSRulesTests: XCTestCase {
    func testExample() async throws {
        let clips = CLIPS()
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
        let clips = CLIPS()
        print(try await clips.eval("(call swift foo 34 TRUE)"))
        print(try await clips.eval("(new swift foo 34 TRUE)"))
    }

    // MARK: - -- Utilities --

    struct CouldNotFindSample: LocalizedError {
        let filename: String
        public var errorDescription: String? { "Could not find sample: \(filename)" }
    }

    // Get the path to a bundled sample clp file
    private func pathFor(sample filename: String) throws -> String {
        guard let doc = Bundle.module.url(forResource: filename,
                                          withExtension: "clp",
                                          subdirectory: "samples")
        else {
            throw  CouldNotFindSample(filename: filename)
        }

        return doc.path(percentEncoded: false)
    }
}
