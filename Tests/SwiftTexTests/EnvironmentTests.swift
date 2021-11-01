//
//  EnvironmentTests.swift
//  SwiftTexTests
//
//  Created by Adam Wulf on 12/6/20.
//

import XCTest
#if canImport(SwiftTexMac)
@testable import SwiftTexMac
#endif
#if canImport(SwiftTex)
@testable import SwiftTex
#endif

class EnvironmentTests: XCTestCase {
    func testSaveToEnv() throws {
        let src = "\\let{ x }{ 2 }"
        let tokens = Lexer(input: src).tokenize().tokens
        let xTok = tokens[2]
        let otherTok = Token(type: xTok.type, range: xTok.range, line: xTok.line + 1, col: xTok.col + 1, loc: xTok.loc, raw: xTok.raw)
        let var1 = VariableNode(name: "x", subscripts: [], startToken: xTok)
        let var2 = VariableNode(name: "x", subscripts: [], startToken: otherTok)
        let val1 = NumberNode(string: "1", startToken: xTok)
        let val2 = NumberNode(string: "2", startToken: xTok)

        var env = Environment()
        env.set(var1, to: val1)
        env.set(var2, to: val2)

        XCTAssertEqual(env.lookup(variable: var1)?.asTex, val2.asTex)
        XCTAssertEqual(env.lookup(variable: var2)?.asTex, val2.asTex)
    }
}
