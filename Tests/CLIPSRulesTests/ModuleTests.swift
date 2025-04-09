// Copyright (c) 2023 David N Main

import Testing
@testable import CLIPSRules

final class ModuleTests: CLIPSTest {

    @Test
    func testSanity() async throws {
        #expect(await clips.currentModule.name == "MAIN")

        try await clips.build("(defmodule Apple (export ?ALL))")
        try await clips.build("(defmodule Banana (export ?ALL))")
        try await clips.build("(deftemplate Apple::foo (slot a))")
        try await clips.build("(deftemplate Banana::bar (slot a))")

        try await clips.build("""
            (defmodule Cherry
                (import Apple ?ALL)
                (import Banana ?ALL))
            """)

        let foo = try await clips.assert(fact: "(foo (a 1))")
        let bar = try await clips.assert(fact: "(bar (a 2))")

        #expect(await clips.currentModule.name == "Cherry")

        // facts
        #expect(await foo.template.module == "Apple")
        #expect(await bar.template.module == "Banana")

        // templates
        #expect(await clips.findTemplate(named: "foo")?.module == "Apple")
        #expect(await clips.findTemplate(named: "bar")?.module == "Banana")
    }
}
