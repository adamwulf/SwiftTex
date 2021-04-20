//
//  ErrorTests.swift
//  
//
//  Created by Adam Wulf on 4/19/21.
//

import XCTest
#if canImport(SwiftTexMac)
@testable import SwiftTexMac
#endif
#if canImport(SwiftTex)
@testable import SwiftTex
#endif

class ErrorTests: XCTestCase {

    func testAddition() throws {
        let source = """
                     x + * y

                     x + 7
                     """
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssertEqual(errors.count, 1)
        if case .UnexpectedToken(let token) = errors.first {
            XCTAssertEqual(token.raw, tokens[2].raw)
        }
        XCTAssertEqual(tokens.count, 8)
        XCTAssertEqual(ast.count, 1)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .plus)
        XCTAssertEqual((plus.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((plus.rhs as? NumberNode)?.value, 7)
    }
}
