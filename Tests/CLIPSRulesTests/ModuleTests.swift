// Copyright (C) 2023 David N Main - All Rights Reserved.
// See LICENSE file for permitted uses.

import XCTest
import CLIPSCore
import CLIPSRules

final class ModuleTests: CLIPSTestBase {

    func testSanity() throws {
        XCTAssertEqual(clips.getName(of: clips.currentModule), "MAIN")

        try clips.build("(defmodule Apple (export ?ALL))")
        try clips.build("(defmodule Banana (export ?ALL))")
        try clips.build("(deftemplate Apple::foo (slot a))")
        try clips.build("(deftemplate Banana::bar (slot a))")

        try clips.build("""
            (defmodule Cherry
                (import Apple ?ALL)
                (import Banana ?ALL))
            """)

        let foo = try clips.assert(fact: "(foo (a 1))")
        let bar = try clips.assert(fact: "(bar (a 2))")

        XCTAssertEqual(clips.getName(of: clips.currentModule), "Cherry")

        // facts
        XCTAssertEqual(clips.getModule(of: clips.getTemplate(for: foo)), "Apple")
        XCTAssertEqual(clips.getModule(of: clips.getTemplate(for: bar)), "Banana")

        // templates
        XCTAssertEqual(clips.getModule(of: clips.findFactTemplate(named: "foo")!), "Apple")
        XCTAssertEqual(clips.getModule(of: clips.findFactTemplate(named: "bar")!), "Banana")
    }
}
