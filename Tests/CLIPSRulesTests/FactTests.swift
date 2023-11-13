// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import XCTest
import CLIPSCore
import CLIPSRules

final class FactTests: CLIPSTestBase {

    // common facts for save and load tests
    private func createSomeFacts(clips: CLIPS.Environment) throws -> Int {
        try clips.build("(deftemplate foo (slot a) (slot b))")
        try clips.build("(deftemplate bar (slot a) (slot b))")

        try clips.buildFacts { builder in
            try builder.using(template: "foo") { t in
                for a in 1...3 {
                    for b in ["one", "two", "three"] {
                        try t.put(slot: "a", value: .integer(a))
                        try t.put(slot: "b", value: .string(b))
                        _ = try t.assertFact()
                    }
                }
            }
            try builder.using(template: "bar") { t in
                for a in 4...6 {
                    for b in ["four", "five", "six"] {
                        try t.put(slot: "a", value: .integer(a))
                        try t.put(slot: "b", value: .symbol(b))
                        _ = try t.assertFact()
                    }
                }
            }
        }

        return 18
    }

    // save current facts to temp file
    private func saveSomeFacts(clips: CLIPS.Environment) -> (Int, URL) {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let filename = "test.facts"
        let fileURL = directory.appendingPathComponent(filename)

        let count = clips.saveFacts(to: fileURL.path(), scope: .visibleToCurrentModule)

        return (count, fileURL)
    }

    // save current facts to temp binary file
    private func saveSomeFactsBinary(clips: CLIPS.Environment) -> (Int, URL) {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let filename = "test.facts.bin"
        let fileURL = directory.appendingPathComponent(filename)

        let count = clips.saveBinaryFacts(to: fileURL.path(), scope: .visibleToCurrentModule)

        return (count, fileURL)
    }

    private func compareFacts(clips1: CLIPS.Environment, clips2: CLIPS.Environment) {
        let facts1 = clips1.getAllFacts()
        let facts2 = clips2.getAllFacts()
        XCTAssertEqual(facts1, facts2)
    }

    func testSaveLoadBinaryFacts() throws {
        let expectedCount = try createSomeFacts(clips: clips)
        let (actualCount, fileURL) = saveSomeFactsBinary(clips: clips)

        XCTAssertEqual(actualCount, expectedCount)

        let engine2 = CLIPS.Engine()
        let clips2 = engine2.environment
        try clips2.build("(deftemplate foo (slot a) (slot b))")
        try clips2.build("(deftemplate bar (slot a) (slot b))")
        let count = clips2.loadBinaryFacts(from: fileURL.path())
        XCTAssertEqual(count, expectedCount)

        compareFacts(clips1: clips, clips2: clips2)
    }

    func testLoadFacts() throws {
        try clips.build("(deftemplate foo (slot a) (slot b))")
        try clips.build("(deftemplate bar (slot a) (slot b))")

        let filePath = try pathFor(sample: "save-comparison", ext: "txt")
        let count = clips.loadFacts(from: filePath)
        XCTAssertEqual(count, 18)

        // save the loaded facts and compare
        let (_, fileURL) = saveSomeFacts(clips: clips)
        let saveContent = try String(contentsOf: fileURL)
        let compContent = try String(contentsOfFile: filePath)
        XCTAssertEqual(saveContent, compContent)
    }

    func testLoadFactsFromString() throws {
        try clips.build("(deftemplate foo (slot a) (slot b))")
        try clips.build("(deftemplate bar (slot a) (slot b))")

        let compContent = try String(contentsOfFile: try pathFor(sample: "save-comparison", ext: "txt"))
        let count = clips.loadFacts(fromString: compContent)
        XCTAssertEqual(count, 18)

        // save the loaded facts and compare
        let (_, fileURL) = saveSomeFacts(clips: clips)
        let saveContent = try String(contentsOf: fileURL)
        XCTAssertEqual(saveContent, compContent)
    }

    func testSaveFacts() throws {
        let expectedCount = try createSomeFacts(clips: clips)
        let (actualCount, fileURL) = saveSomeFacts(clips: clips)

        XCTAssertEqual(actualCount, expectedCount)

        let saveContent = try String(contentsOf: fileURL)
        let compContent = try String(contentsOfFile: try pathFor(sample: "save-comparison", ext: "txt"))
        XCTAssertEqual(saveContent, compContent)
    }

    func testRetract() throws {
        try clips.build("(deftemplate foo (slot a) (slot b))")
        let fact = try clips.assert(fact: "(foo (a 23) (b apple))")
        clips.retain(fact: fact)
        XCTAssertTrue(clips.factExists(fact))

        try clips.retract(fact: fact)
        XCTAssertFalse(clips.factExists(fact))

        clips.release(fact: fact)
    }

    func testPrettyPrint() throws {
        try clips.build("(deftemplate foo (slot a) (slot b))")
        let fact = try clips.assert(fact: "(foo (a 23) (b apple))")

        let pretty = clips.prettyPrint(fact: fact)
        XCTAssertEqual(pretty, "(foo \n   (a 23) \n   (b apple))")
    }

    func testAssertTemplate() throws {
        try clips.build("(deftemplate foo (slot a) (slot b))")
        try clips.build("(deftemplate bar (slot a) (slot b (default 10)))")

        var foo1: CLIPS.Fact?
        var foo2: CLIPS.Fact?
        var bar1: CLIPS.Fact?
        var bar2: CLIPS.Fact?

        try clips.buildFacts { builder in
            try builder.using(template: "foo") { t in
                try t.put(slot: "a", value: .integer(45))
                foo1 = try t.assertFact()
                foo2 = try t.assertFact()
            }
            try builder.using(template: "bar") { t in
                bar1 = try t.assertFact()
                bar2 = try t.assertFact()
            }
        }

        XCTAssertNotNil(foo1)
        XCTAssertNotNil(foo2)
        XCTAssertNotNil(bar1)
        XCTAssertNotNil(bar2)

        XCTAssertEqual(try clips.getSlot(of: foo1!, named: "a"),
                       .integer(45))
        XCTAssertEqual(try clips.getSlot(of: foo2!, named: "a"),
                       .symbol("nil"))
        XCTAssertEqual(try clips.getSlot(of: bar1!, named: "b"),
                       .integer(10))
    }

    func testSlotNames() throws {
        try clips.build("""
            (deftemplate foo
              (slot bar)
              (slot bat))
            """)

        let foo = clips.findFactTemplate(named: "foo")
        guard let foo else {
            XCTFail("could not find template")
            return
        }

        let names = clips.getSlotNames(for: foo)
        XCTAssertEqual(names, ["bar", "bat"])

        // implied name
        let fact = try clips.assert(fact: "(hello world again)")
        let template = clips.getTemplate(for: fact)
        let name2 = clips.getSlotNames(for: template)
        XCTAssertEqual(name2, [CLIPS.FactTemplate.IMPLIED_SLOT_NAME])
    }

    func testTemplateName() throws {
        try clips.build("(deftemplate foo (slot a))")

        let foo1 = try clips.assert(fact: "(foo (a 1))")
        let foo = clips.findFactTemplate(named: "foo")
        let template = clips.getTemplate(for: foo1)
        let name = clips.getName(of: template)

        XCTAssertEqual(template, foo)
        XCTAssertEqual(name, "foo")

        let fact = try clips.assert(fact: "(hello world again)")
        let template2 = clips.getTemplate(for: fact)
        let name2 = clips.getName(of: template2)
        XCTAssertEqual(name2, "hello")
    }

    func testListingFacts() throws {
        try clips.build("(deftemplate foo (slot a))")
        try clips.build("(deftemplate bar (slot a))")

        let foo1 = try clips.assert(fact: "(foo (a 1))")
        let bar1 = try clips.assert(fact: "(bar (a 1))")
        let foo2 = try clips.assert(fact: "(foo (a 2))")
        let bar2 = try clips.assert(fact: "(bar (a 2))")

        var fact: CLIPS.Fact? = nil
        fact = clips.getNextFact(after: fact)
        XCTAssertEqual(fact, foo1)
        fact = clips.getNextFact(after: fact)
        XCTAssertEqual(fact, bar1)
        fact = clips.getNextFact(after: fact)
        XCTAssertEqual(fact, foo2)
        fact = clips.getNextFact(after: fact)
        XCTAssertEqual(fact, bar2)
        fact = clips.getNextFact(after: fact)
        XCTAssertNil(fact)

        let foo = clips.findFactTemplate(named: "foo")
        let bar = clips.findFactTemplate(named: "bar")
        guard let foo, let bar else {
            XCTFail("could not find templates")
            return
        }

        fact = clips.getNextFact(in: foo, after: nil)
        XCTAssertEqual(fact, foo1)
        fact = clips.getNextFact(in: foo, after: fact)
        XCTAssertEqual(fact, foo2)
        fact = clips.getNextFact(in: foo, after: fact)
        XCTAssertNil(fact)

        fact = clips.getNextFact(in: bar, after: nil)
        XCTAssertEqual(fact, bar1)
        fact = clips.getNextFact(in: bar, after: fact)
        XCTAssertEqual(fact, bar2)
        fact = clips.getNextFact(in: bar, after: fact)
        XCTAssertNil(fact)
    }

    func testFindTemplate() throws {
        try clips.build("""
            (deftemplate foo
              (slot bar)
              (slot bat))
            """)

        let foo = clips.findFactTemplate(named: "foo")
        let bar = clips.findFactTemplate(named: "bar")

        XCTAssertNotNil(foo)
        XCTAssertNil(bar)
    }

    func testGetImpliedSlot() throws {
        let fact = try clips.assert(fact: "(foo bar 23 \"hello\")")

        let slot = try clips.getSlot(of: fact, named: CLIPS.FactTemplate.IMPLIED_SLOT_NAME)

        XCTAssertEqual(slot, .multifield([.symbol("bar"), .integer(23), .string("hello")]))
    }

    func testGetNamedSlot() throws {
        try clips.build("""
            (deftemplate foo
              (slot bar)
              (slot bat))
            """)

        let fact = try clips.assert(fact: "(foo (bar 23) (bat apple))")

        let bar = try clips.getSlot(of: fact, named: "bar")
        let bat = try clips.getSlot(of: fact, named: "bat")

        XCTAssertEqual(bar, .integer(23))
        XCTAssertEqual(bat, .symbol("apple"))

        do {
            _ = try clips.getSlot(of: fact, named: "baz")
        } catch CLIPS.GetSlotError.slotNotFound {
            // Success
            return
        }

        XCTFail("did not throw slotNotFound")
    }
}
