// Copyright (c) 2025 David N Main

import Foundation
import Testing
import CLIPSRules

@Suite(.serialized)
final class FactTests: CLIPSTest {

    // common facts for save and load tests
    private func createSomeFacts(clips: CLIPSEnvironment) async throws -> Int {
        try await clips.build("(deftemplate foo (slot a) (slot b))")
        try await clips.build("(deftemplate bar (slot a) (slot b))")

        try await clips.buildFacts { builder in
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
    private func saveSomeFacts(clips: CLIPSEnvironment) async -> (Int, URL) {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let filename = "test.facts"
        let fileURL = directory.appendingPathComponent(filename)

        let count = await clips.saveFacts(to: fileURL.path(), scope: .visibleToCurrentModule)

        return (count, fileURL)
    }

    // save current facts to temp binary file
    private func saveSomeFactsBinary(clips: CLIPSEnvironment) async -> (Int, URL) {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let filename = "test.facts.bin"
        let fileURL = directory.appendingPathComponent(filename)

        let count = await clips.saveBinaryFacts(to: fileURL.path(), scope: .visibleToCurrentModule)

        return (count, fileURL)
    }

    private func compareFacts(clips1: CLIPSEnvironment, clips2: CLIPSEnvironment) async throws {
        struct Fact: Equatable {
            let templateName: String
            let slots: [String: CLIPSValue]
        }

        func allFacts(_ clips: CLIPSEnvironment) async throws -> [Fact] {
            var facts = [Fact]()

            var maybeFact = await clips.getFirstFact()
            while let fact = maybeFact {
                let template = fact.template
                var slots = [String: CLIPSValue]()
                for slotName in await template.getSlotNames() {
                    slots[slotName] = try await fact.getSlot(named: slotName)
                }

                facts.append(.init(templateName: template.name, slots: slots))
                maybeFact = await fact.getNextFact()
            }

            return facts
        }

        let facts1 = try await allFacts(clips1)
        let facts2 = try await allFacts(clips2)
        #expect(facts1 == facts2)
    }

    @Test
    func testSaveLoadBinaryFacts() async throws {
        let expectedCount = try await createSomeFacts(clips: clips)
        let (actualCount, fileURL) = await saveSomeFactsBinary(clips: clips)

        #expect(actualCount == expectedCount)

        let clips2 = try CLIPSEnvironment()
        try await clips2.build("(deftemplate foo (slot a) (slot b))")
        try await clips2.build("(deftemplate bar (slot a) (slot b))")
        let count = await clips2.loadBinaryFacts(from: fileURL.path())
        #expect(count == expectedCount)

        try await compareFacts(clips1: clips, clips2: clips2)
    }

    @Test
    func testLoadFacts() async throws {
        try await clips.build("(deftemplate foo (slot a) (slot b))")
        try await clips.build("(deftemplate bar (slot a) (slot b))")

        let filePath = try pathFor(sample: "save-comparison", ext: "txt")
        let count = await clips.loadFacts(from: filePath)
        #expect(count == 18)

        // save the loaded facts and compare
        let (_, fileURL) = await saveSomeFacts(clips: clips)
        let saveContent = try String(contentsOf: fileURL)
        let compContent = try String(contentsOfFile: filePath)
        #expect(saveContent == compContent)
    }

    @Test
    func testLoadFactsFromString() async throws {
        try await clips.build("(deftemplate foo (slot a) (slot b))")
        try await clips.build("(deftemplate bar (slot a) (slot b))")

        let compContent = try String(contentsOfFile: try pathFor(sample: "save-comparison", ext: "txt"))
        let count = await clips.loadFacts(fromString: compContent)
        #expect(count == 18)

        // save the loaded facts and compare
        let (_, fileURL) = await saveSomeFacts(clips: clips)
        let saveContent = try String(contentsOf: fileURL)
        #expect(saveContent == compContent)
    }

    @Test
    func testSaveFacts() async throws {
        let expectedCount = try await createSomeFacts(clips: clips)
        let (actualCount, fileURL) = await saveSomeFacts(clips: clips)

        #expect(actualCount == expectedCount)

        let saveContent = try String(contentsOf: fileURL)
        let compContent = try String(contentsOfFile: try pathFor(sample: "save-comparison", ext: "txt"))
        #expect(saveContent == compContent)
    }

    @Test
    func testRetract() async throws {
        try await clips.build("(deftemplate foo (slot a) (slot b))")
        let fact = try await clips.assert(fact: "(foo (a 23) (b apple))")
        #expect(fact.isAsserted)

        try await fact.retract()
        #expect(!fact.isAsserted)
    }

    @Test
    func testPrettyPrint() async throws {
        try await clips.build("(deftemplate foo (slot a) (slot b))")
        let fact = try await clips.assert(fact: "(foo (a 23) (b apple))")

        let pretty = await fact.prettyPrint()
        #expect(pretty == "(foo \n   (a 23) \n   (b apple))")
    }

    @Test
    func testAssertTemplate() async throws {
        try await clips.build("(deftemplate foo (slot a) (slot b))")
        try await clips.build("(deftemplate bar (slot a) (slot b (default 10)))")

        var foo1: CLIPSFact?
        var foo2: CLIPSFact?
        var bar1: CLIPSFact?
        var bar2: CLIPSFact?

        try await clips.buildFacts { builder in
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

        #expect(foo1 != nil)
        #expect(foo2 != nil)
        #expect(bar1 != nil)
        #expect(bar2 != nil)

        await #expect(try foo1!.getSlot(named: "a") == .integer(45))
        await #expect(try foo2!.getSlot(named: "a") == .symbol("nil"))
        await #expect(try bar1!.getSlot(named: "b") == .integer(10))
    }

    @Test
    func testSlotNames() async throws {
        try await clips.build("""
            (deftemplate foo
              (slot bar)
              (slot bat))
            """)

        let foo = await clips.findTemplate(named: "foo")
        guard let foo else {
            Issue.record("could not find template")
            return
        }

        let names = await foo.getSlotNames()
        #expect(names == ["bar", "bat"])

        // implied name
        let fact = try await clips.assert(fact: "(hello world again)")
        let template = fact.template
        let name2 = await template.getSlotNames()
        #expect(name2 == [CLIPSTemplate.IMPLIED_SLOT_NAME])
    }

    @Test
    func testTemplateName() async throws {
        try await clips.build("(deftemplate foo (slot a))")

        let foo1 = try await clips.assert(fact: "(foo (a 1))")
        let foo = await clips.findTemplate(named: "foo")
        let template = foo1.template
        let name = template.name

        #expect(template == foo)
        #expect(name == "foo")

        let fact = try await clips.assert(fact: "(hello world again)")
        let template2 = fact.template
        let name2 = template2.name
        #expect(name2 == "hello")
    }

    @Test
    func testListingFacts() async throws {
        try await clips.build("(deftemplate foo (slot a))")
        try await clips.build("(deftemplate bar (slot a))")

        let foo1 = try await clips.assert(fact: "(foo (a 1))")
        let bar1 = try await clips.assert(fact: "(bar (a 1))")
        let foo2 = try await clips.assert(fact: "(foo (a 2))")
        let bar2 = try await clips.assert(fact: "(bar (a 2))")

        var fact: CLIPSFact? = nil
        fact = await clips.getFirstFact()
        #expect(fact == foo1)
        fact = await fact?.getNextFact()
        #expect(fact == bar1)
        fact = await fact?.getNextFact()
        #expect(fact == foo2)
        fact = await fact?.getNextFact()
        #expect(fact == bar2)
        fact = await fact?.getNextFact()
        #expect(fact == nil)

        let foo = await clips.findTemplate(named: "foo")
        let bar = await clips.findTemplate(named: "bar")
        guard let foo, let bar else {
            Issue.record("could not find templates")
            return
        }

        fact = await foo.getFirstFact()
        #expect(fact == foo1)
        fact = await foo.getNextFact(after: fact!)
        #expect(fact == foo2)
        fact = await foo.getNextFact(after: fact!)
        #expect(fact == nil)

        fact = await bar.getFirstFact()
        #expect(fact == bar1)
        fact = await bar.getNextFact(after: fact!)
        #expect(fact == bar2)
        fact = await bar.getNextFact(after: fact!)
        #expect(fact == nil)
    }

    @Test
    func testFindTemplate() async throws {
        try await clips.build("""
            (deftemplate foo
              (slot bar)
              (slot bat))
            """)

        let foo = await clips.findTemplate(named: "foo")
        let bar = await clips.findTemplate(named: "bar")

        #expect(foo != nil)
        #expect(bar == nil)
    }

    @Test
    func testGetImpliedSlot() async throws {
        let fact = try await clips.assert(fact: "(foo bar 23 \"hello\")")

        let slot = try await fact.getSlot(named: CLIPSTemplate.IMPLIED_SLOT_NAME)

        #expect(slot == .multifield([.symbol("bar"), .integer(23), .string("hello")]))
    }

    @Test
    func testGetNamedSlot() async throws {
        try await clips.build("""
            (deftemplate foo
              (slot bar)
              (slot bat))
            """)

        let fact = try await clips.assert(fact: "(foo (bar 23) (bat apple))")

        let bar = try await fact.getSlot(named: "bar")
        let bat = try await fact.getSlot(named: "bat")

        #expect(bar == .integer(23))
        #expect(bat == .symbol("apple"))

        do {
            _ = try await fact.getSlot(named: "baz")
        } catch CLIPSGetSlotError.slotNotFound {
            // Success
            return
        }

        Issue.record("did not throw slotNotFound")
    }
}
