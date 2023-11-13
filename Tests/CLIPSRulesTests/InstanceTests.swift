// Copyright (C) 2024 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import XCTest
import CLIPSCore
import CLIPSRules

final class InstanceTests: CLIPSTestBase {

    // common instances for save and load tests
    private func createSomeInstances(clips: CLIPS.Environment) throws -> Int {
        try clips.build("(defclass foo (is-a USER) (slot a) (slot b))")
        try clips.build("(defclass bar (is-a USER) (slot a) (slot b))")

        try clips.buildInstances { builder in
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
    private func saveSomeInstances(clips: CLIPS.Environment) -> (Int, URL) {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let filename = "test.instances"
        let fileURL = directory.appendingPathComponent(filename)

        let count = clips.saveInstances(to: fileURL.path(), scope: .visibleToCurrentModule)

        return (count, fileURL)
    }

    // save current instances to temp binary file
    private func saveSomeInstancesBinary(clips: CLIPS.Environment) -> (Int, URL) {
        let fileManager = FileManager.default
        let directory = fileManager.temporaryDirectory
        let filename = "test.instances.bin"
        let fileURL = directory.appendingPathComponent(filename)

        let count = clips.saveBinaryInstances(to: fileURL.path(), scope: .visibleToCurrentModule)

        return (count, fileURL)
    }

    private func compareInstances(clips1: CLIPS.Environment, clips2: CLIPS.Environment) {
        let instances1 = clips1.getAllInstances()
        let instances2 = clips2.getAllInstances()
        XCTAssertEqual(instances1, instances2)
    }

    func testSanity() throws {
        _ = try createSomeInstances(clips: clips)

        guard let instance = clips.findInstance(named: "foo-3-two") else {
            XCTFail("Did not find instance foo-3-two")
            return
        }

        XCTAssertEqual(try clips.directGetSlot(of: instance, named: "a"), CLIPS.Value.integer(3))
        XCTAssertEqual(try clips.directGetSlot(of: instance, named: "b"), CLIPS.Value.string("two"))

        try clips.directSetSlot(of: instance, named: "a", to: 43)
        XCTAssertEqual(try clips.directGetSlot(of: instance, named: "a"), CLIPS.Value.integer(43))
        XCTAssertEqual(try clips.directGetSlot(of: instance, named: "b"), CLIPS.Value.string("two"))
    }

    func testSaveLoadBinaryInstances() throws {
        let expectedCount = try createSomeInstances(clips: clips)
        let (actualCount, fileURL) = saveSomeInstancesBinary(clips: clips)

        XCTAssertEqual(actualCount, expectedCount)

        let engine2 = CLIPS.Engine()
        let clips2 = engine2.environment
        try clips2.build("(defclass foo (is-a USER) (slot a) (slot b))")
        try clips2.build("(defclass bar (is-a USER) (slot a) (slot b))")
        let count = clips2.loadBinaryInstances(from: fileURL.path())
        XCTAssertEqual(count, expectedCount)

        compareInstances(clips1: clips, clips2: clips2)
    }
}
