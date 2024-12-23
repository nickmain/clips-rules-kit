// Copyright (c) 2023 David N Main

import Testing
@testable import CLIPSRules

final class CLIPSValueTests: CLIPSTest {

    @Test
    func testString() throws {
        let value = try clips.eval("\"hello\"")
        #expect(value == .string("hello"))
    }

    @Test
    func testFloat() throws {
        let value = try clips.eval("3.4")
        #expect(value == .float(3.4))
    }

    @Test
    func testInteger() throws {
        let value = try clips.eval("21")
        #expect(value == .integer(21))
    }

    @Test
    func testBool() throws {
        let value = try clips.eval("TRUE")
        #expect(value == .boolean(true))
    }

    @Test
    func testSymbol() throws {
        let value = try clips.eval("hello")
        #expect(value == .symbol("hello"))
    }

    @Test
    func testMultifield() throws {
        let value = try clips.eval("(create$ 1 FALSE foo \"hello\" 9.1)")
        #expect(value == .multifield([
            .integer(1), .boolean(false), .symbol("foo"), .string("hello"), .float(9.1)
        ]))
    }
}
