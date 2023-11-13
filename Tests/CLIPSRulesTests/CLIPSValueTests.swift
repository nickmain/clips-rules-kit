// Copyright (c) 2023 David N Main

import XCTest
import CLIPSCore
import CLIPSRules

final class CLIPSValueTests: CLIPSTestBase {

    func testString() throws {
        let value = try clips.eval("\"hello\"")
        XCTAssertEqual(value, .string("hello"))
    }

    func testFloat() throws {
        let value = try clips.eval("3.4")
        XCTAssertEqual(value, .float(3.4))
    }

    func testInteger() throws {
        let value = try clips.eval("21")
        XCTAssertEqual(value, .integer(21))
    }

    func testBool() throws {
        let value = try clips.eval("TRUE")
        XCTAssertEqual(value, .boolean(true))
    }

    func testSymbol() throws {
        let value = try clips.eval("hello")
        XCTAssertEqual(value, .symbol("hello"))
    }

    func testMultifield() throws {
        let value = try clips.eval("(create$ 1 FALSE foo \"hello\" 9.1)")
        XCTAssertEqual(value, .multifield([
            .integer(1), .boolean(false), .symbol("foo"), .string("hello"), .float(9.1)
        ]))
    }
}
