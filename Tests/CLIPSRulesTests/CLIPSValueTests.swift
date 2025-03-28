// Copyright (c) 2023 David N Main

import Testing
@testable import CLIPSRules

final class CLIPSValueTests: CLIPSTest {

    @Test
    func testString() async throws {
        let value = try await clips.eval("\"hello\"")
        #expect(value == .string("hello"))
    }

    @Test
    func testFloat() async throws {
        let value = try await clips.eval("3.4")
        #expect(value == .float(3.4))
    }

    @Test
    func testInteger() async throws {
        let value = try await clips.eval("21")
        #expect(value == .integer(21))
    }

    @Test
    func testBool() async throws {
        let value = try await clips.eval("TRUE")
        #expect(value == .boolean(true))
    }

    @Test
    func testSymbol() async throws {
        let value = try await clips.eval("hello")
        #expect(value == .symbol("hello"))
    }

    @Test
    func testMultifield() async throws {
        let value = try await clips.eval("(create$ 1 FALSE foo \"hello\" 9.1)")
        #expect(value == .multifield([
            .integer(1), .boolean(false), .symbol("foo"), .string("hello"), .float(9.1)
        ]))
    }
}
