// Copyright (c) 2023 David N Main

import Foundation
import Testing
import CLIPSRules

final class InstanceTests: CLIPSTest {

    // common instances for save and load tests
    private func createSomeInstances(clips: CLIPSEnvironment) async throws -> Int {
        try await clips.build("(defclass foo (is-a USER) (slot a) (slot b))")
        try await clips.build("(defclass bar (is-a USER) (slot a) (slot b))")

        try await clips.buildInstances { builder in
            try builder.using(className: "foo") { bc in
                for a in 1...3 {
                    for b in ["one", "two", "three"] {
                        try bc.put(slot: "a", value: .integer(a))
                        try bc.put(slot: "b", value: .string(b))
                        _ = try bc.makeInstance(named: "foo-\(a)-\(b)")
                    }
                }
            }
            try builder.using(className: "bar") { bc in
                for a in 4...6 {
                    for b in ["four", "five", "six"] {
                        try bc.put(slot: "a", value: .integer(a))
                        try bc.put(slot: "b", value: .string(b))
                        _ = try bc.makeInstance(named: "bar-\(a)-\(b)")
                    }
                }
            }
        }

        return 18
    }

    // save current instances to temp file
    private func saveSomeInstances(clips: CLIPSEnvironment) async -> (Int, URL) {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let filename = "test.instances"
        let fileURL = directory.appendingPathComponent(filename)

        let count = await clips.saveInstances(to: fileURL.path(), scope: .visibleToCurrentModule)

        return (count, fileURL)
    }

    // save current instances to temp binary file
    private func saveSomeInstancesBinary(clips: CLIPSEnvironment) async -> (Int, URL) {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let filename = "test.instances.bin"
        let fileURL = directory.appendingPathComponent(filename)

        let count = await clips.saveBinaryInstances(to: fileURL.path(), scope: .visibleToCurrentModule)

        return (count, fileURL)
    }

    private func compareInstances(clips1: CLIPSEnvironment, clips2: CLIPSEnvironment) async throws {
        struct Instance: Hashable {
            let instanceName: String
            let className: String
            let instanceSlots: [String: CLIPSValue]

            func hash(into hasher: inout Hasher) {
                hasher.combine(instanceName)
                hasher.combine(className)
            }

            static func == (lhs: Instance, rhs: Instance) -> Bool {
                return lhs.instanceName == rhs.instanceName
                    && lhs.className == rhs.className
                    && lhs.instanceSlots == rhs.instanceSlots
            }
        }

        func getAllInstances(_ clips: CLIPSEnvironment) async throws -> Set<Instance> {
            var set = Set<Instance>()

            var maybeInstance = await clips.getFirstInstance()
            #expect(maybeInstance != nil)
            while let instance = maybeInstance {
                var slots = [String: CLIPSValue]()
                for slotName in await instance.clipsClass.getSlotNames() {
                    let slotValue = try await instance.directGetSlot(named: slotName)
                    slots[slotName] = slotValue
                }

                set.insert(Instance(instanceName: instance.name,
                                    className: instance.clipsClass.name,
                                    instanceSlots: slots))
                maybeInstance = await instance.getNextInstance()
            }

            return set
        }

        let instances1 = try await getAllInstances(clips)
        let instances2 = try await getAllInstances(clips2)
        #expect(instances1 == instances2)
    }

    @Test
    func testSanity() async throws {
        _ = try await createSomeInstances(clips: clips)

        guard let instance = await clips.findInstance(named: "foo-3-two") else {
            Issue.record("Did not find instance foo-3-two")
            return
        }

        await #expect(try instance.directGetSlot(named: "a") == CLIPSValue.integer(3))
        await #expect(try instance.directGetSlot(named: "b") == CLIPSValue.string("two"))

        try await instance.directSetSlot(named: "a", to: .integer(43))
        await #expect(try instance.directGetSlot(named: "a") == CLIPSValue.integer(43))
        await #expect(try instance.directGetSlot(named: "b") == CLIPSValue.string("two"))
    }

    @Test
    func testSaveLoadBinaryInstances() async throws {
        let expectedCount = try await createSomeInstances(clips: clips)
        let (actualCount, fileURL) = await saveSomeInstancesBinary(clips: clips)

        #expect(actualCount == expectedCount)

        let clips2 = try CLIPSEnvironment()
        try await clips2.build("(defclass foo (is-a USER) (slot a) (slot b))")
        try await clips2.build("(defclass bar (is-a USER) (slot a) (slot b))")
        let count = await clips2.loadBinaryInstances(from: fileURL.path())
        #expect(count == expectedCount)

        try await compareInstances(clips1: clips, clips2: clips2)
    }
}
