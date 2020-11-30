//
//  SwiftTexTests.swift
//  SwiftTexTests
//
//  Created by Adam Wulf on 11/30/20.
//

import XCTest
@testable import SwiftTex

class SwiftTexTests: XCTestCase {

    func testExample() throws {
        let source = multiline(
            "def foo(x, y)",
            "  x + y * 2 + (4 + 5) / 3",
            "",
            "foo(3, 4)"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertEqual(tokens.count, 26)
        XCTAssertNotNil(ast.first as? FunctionNode)
    }
}
