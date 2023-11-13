// Copyright (c) 2023 David N Main

import XCTest
import CLIPSRules

final class UserDefinedFunctionTests: CLIPSTestBase {

    func testSanity() throws {
        try clips.addUserDefinedFunction(named: "foo") { _ in
            print("HELLO WORLD!!")
        }

        try clips.eval("(foo)")
    }

    func testGettingArguments() throws {
        try clips.addUserDefinedFunction(named: "foo") { invocation in
            XCTAssertEqual(invocation.getArguments(), [.integer(1), .boolean(false), .multifield([.symbol("a"), .integer(2)])])
        }
        try clips.eval("(foo 1 FALSE (create$ a 2))")
    }

    func testSettingResult() throws {
        try clips.addUserDefinedFunction(named: "foo") { invocation in
            invocation.setReturn(value: .string("hello"))
        }
        let result = try clips.eval("(foo)")
        XCTAssertEqual(result, .string("hello"))

        try clips.addUserDefinedFunction(named: "foo2") { invocation in
            invocation.setReturn(value: .multifield([.boolean(true), .symbol("bar")]))
        }
        let result2 = try clips.eval("(foo2)")
        XCTAssertEqual(result2, .multifield([.boolean(true), .symbol("bar")]))
    }

    // test setting the error
    func testSetError() throws {
        try clips.addUserDefinedFunction(named: "foo") { invocation in
            invocation.setError(.multifield([.integer(23), .symbol("oops")]))
        }

        try clips.eval("(foo)")
        let error = try clips.eval("(get-error)")
        XCTAssertEqual(error, .multifield([.integer(23), .symbol("oops")]))
    }

    // test throw error
    func testThrowError() throws {
        try clips.addUserDefinedFunction(named: "foo") { invocation in
            invocation.throwError()
        }

        do {
            try clips.eval("(foo)")
        } catch CLIPS.EvalError.processingError {
            // success
            return
        }

        XCTFail("error was not thrown")
    }

    // test argument count property
    func testArgCount() throws {
        try clips.addUserDefinedFunction(named: "foo") { invocation in
            XCTAssertEqual(invocation.argCount, 3, "arg count")
        }

        try clips.eval("(foo 1 2 3)")
    }

    // test argument type constraints
    func testArgTypes() throws {
        func badCall(_ expression: String, _ message: String) throws {
            do {
                try clips.eval(expression)
                XCTFail(message)
            } catch CLIPS.EvalError.parseError {
                // success
            }
        }

        try clips.addUserDefinedFunction(named: "foo", argTypes: .init(defaultTypes: [.double, .symbol])) { _ in
            print("HELLO WORLD!!")
        }

        try clips.eval("(foo 1.0 bar 3.4 baz)")
        try badCall("(foo 1)", "accepted int")
        try badCall("(foo \"hello\")", "accepted string")

        try clips.addUserDefinedFunction(named: "bar", argTypes: .init(defaultTypes: [.symbol, .fact], positionalTypes: [[.symbol],[.boolean]])) { _ in
            print("HELLO WORLD!!")
        }

        try clips.eval("(bar a TRUE b)")
        try badCall("(bar a TRUE 1)", "accepted int")
        try badCall("(bar a TRUE \"hello\")", "accepted string")

        // Note: omitting a position in order to use default types appears
        // to be broken in CLIPS
    }

    // test arg count constraints
    func testArgCounts() throws {
        try clips.addUserDefinedFunction(named: "foo", argCount: 1...3) { _ in
            print("HELLO WORLD!!")
        }

        try clips.eval("(foo 1)")
        try clips.eval("(foo 1 2)")
        try clips.eval("(foo 1 2 3)")

        do {
            try clips.eval("(foo 1 2 3 4)")
            XCTFail("4 args not rejected")
        } catch CLIPS.EvalError.parseError {
            // success - 4 args should be rejected
        }

        do {
            try clips.eval("(foo)")
            XCTFail("zero args not rejected")
        } catch CLIPS.EvalError.parseError {
            // success - zero args should be rejected
        }
    }

    // test that duplicate UDF names are rejected
    func testDuplicateNames() throws {
        try clips.addUserDefinedFunction(named: "foo") { _ in
            print("HELLO WORLD!!")
        }

        do {
            try clips.addUserDefinedFunction(named: "foo") { _ in
                print("YET AGAIN")
            }
            XCTFail("Duplicate UDF name foo not rejected")
        } catch CLIPS.AddUDFError.functionNameInUse {
            // success
        }
    }
}
