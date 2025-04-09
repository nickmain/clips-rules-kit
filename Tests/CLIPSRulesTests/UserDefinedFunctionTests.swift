// Copyright (c) 2023 David N Main

import Testing
import CLIPSRules

final class UserDefinedFunctionTests: CLIPSTest {

    @Test
    func testSanity() async throws {
        try await clips.addUserDefinedFunction(named: "foo") { _ in
            print("HELLO WORLD!!")
        }

        try await clips.eval("(foo)")
    }

    @Test
    func testGettingArguments() async throws {
        try await clips.addUserDefinedFunction(named: "foo") { invocation in
            #expect(invocation.getArguments() == [.integer(1), .boolean(false), .multifield([.symbol("a"), .integer(2)])])
        }
        try await clips.eval("(foo 1 FALSE (create$ a 2))")
    }

    @Test
    func testSettingResult() async throws {
        try await clips.addUserDefinedFunction(named: "foo") { invocation in
            invocation.setReturn(value: .string("hello"))
        }
        let result = try await clips.eval("(foo)")
        #expect(result == .string("hello"))

        try await clips.addUserDefinedFunction(named: "foo2") { invocation in
            invocation.setReturn(value: .multifield([.boolean(true), .symbol("bar")]))
        }
        let result2 = try await clips.eval("(foo2)")
        #expect(result2 == .multifield([.boolean(true), .symbol("bar")]))
    }

    // test setting the error
    @Test
    func testSetError() async throws {
        try await clips.addUserDefinedFunction(named: "foo") { invocation in
            invocation.setError(.multifield([.integer(23), .symbol("oops")]))
        }

        try await clips.eval("(foo)")
        let error = try await clips.eval("(get-error)")
        #expect(error == .multifield([.integer(23), .symbol("oops")]))
    }

    // test throw error
    @Test
    func testThrowError() async throws {
        try await clips.addUserDefinedFunction(named: "foo") { invocation in
            invocation.throwError()
        }

        do {
            try await clips.eval("(foo)")
        } catch CLIPSEvalError.processingError {
            // success
            return
        }

        Issue.record("error was not thrown")
    }

    // test argument count property
    @Test
    func testArgCount() async throws {
        try await clips.addUserDefinedFunction(named: "foo") { invocation in
            #expect(invocation.argCount == 3)
        }

        try await clips.eval("(foo 1 2 3)")
    }

    // test argument type constraints
    @Test
    func testArgTypes() async throws {
        func badCall(_ expression: String, _ message: String) async throws {
            do {
                try await clips.eval(expression)
                Issue.record(Comment(rawValue: message))
            } catch CLIPSEvalError.parseError {
                // success
                print("❌ Caught error")
            }
        }

        try await clips.addUserDefinedFunction(named: "foo", argTypes: .init(defaultTypes: [.double, .symbol])) { _ in
            print("✅ HELLO WORLD!!")
        }

        try await clips.eval("(foo 1.0 bar 3.4 baz)")
        try await badCall("(foo 1)", "accepted int")
        try await badCall("(foo \"hello\")", "accepted string")

        try await clips.addUserDefinedFunction(named: "bar", argTypes: .init(defaultTypes: [.symbol, .fact], positionalTypes: [[.symbol],[.boolean]])) { _ in
            print("✅ HELLO WORLD!!")
        }

        try await clips.eval("(bar a TRUE b)")
        try await badCall("(bar a TRUE 1)", "accepted int")
        try await badCall("(bar a TRUE \"hello\")", "accepted string")

        // Note: omitting a position in order to use default types appears
        // to be broken in CLIPS
    }

    // test arg count constraints
    @Test
    func testArgCounts() async throws {
        try await clips.addUserDefinedFunction(named: "foo", argCount: 1...3) { _ in
            print("HELLO WORLD!!")
        }

        try await clips.eval("(foo 1)")
        try await clips.eval("(foo 1 2)")
        try await clips.eval("(foo 1 2 3)")

        do {
            try await clips.eval("(foo 1 2 3 4)")
            Issue.record("4 args not rejected")
        } catch CLIPSEvalError.parseError {
            // success - 4 args should be rejected
        }

        do {
            try await clips.eval("(foo)")
            Issue.record("zero args not rejected")
        } catch CLIPSEvalError.parseError {
            // success - zero args should be rejected
        }
    }

    // test that duplicate UDF names are rejected
    @Test
    func testDuplicateNames() async throws {
        try await clips.addUserDefinedFunction(named: "foo") { _ in
            print("HELLO WORLD!!")
        }

        do {
            try await clips.addUserDefinedFunction(named: "foo") { _ in
                print("YET AGAIN")
            }
            Issue.record("Duplicate UDF name foo not rejected")
        } catch CLIPSAddUDFError.functionNameInUse {
            // success
        }
    }
}
