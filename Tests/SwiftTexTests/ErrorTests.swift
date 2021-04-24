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
            XCTAssertEqual(token.line, 1)
            XCTAssertEqual(token.col, 4)
            XCTAssertEqual(token.loc, 4)
            XCTAssertEqual(token.raw, tokens[2].raw)
        } else {
            XCTFail()
        }
        XCTAssertEqual(tokens.count, 8)
        XCTAssertEqual(ast.count, 1)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .plus)
        XCTAssertEqual((plus.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((plus.rhs as? NumberNode)?.value, 7)
    }

    func testEndlineLocation() throws {
        let source = """
                     x + y

                     x + * 7
                     """
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let endlToken = tokens[3]

        XCTAssertEqual(tokens.count, 8)
        XCTAssertEqual(endlToken.line, 1)
        XCTAssertEqual(endlToken.col, 5)
        XCTAssertEqual(endlToken.loc, 5)

        let nextToken = tokens[4]

        XCTAssertEqual(nextToken.line, 3)
        XCTAssertEqual(nextToken.col, 0)
        XCTAssertEqual(nextToken.loc, 7)
    }

    func testLineWrapLocation() throws {
        let source = """
                     x + y
                     * 7
                     """
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let lastToken = tokens[4]

        XCTAssertEqual(tokens.count, 5)
        XCTAssertEqual(lastToken.line, 2)
        XCTAssertEqual(lastToken.col, 2)
        XCTAssertEqual(lastToken.loc, 8)
    }

    func testFailedAfterLinebreak() throws {
        let source = """
                     x + y

                     x + * 7
                     """
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssertEqual(errors.count, 1)
        if case .UnexpectedToken(let token) = errors.first {
            XCTAssertEqual(token.line, 3)
            XCTAssertEqual(token.col, 4)
            XCTAssertEqual(token.loc, 11)
            XCTAssertEqual(token.raw, tokens[6].raw)
        } else {
            XCTFail()
        }
        XCTAssertEqual(tokens.count, 8)
        XCTAssertEqual(ast.count, 1)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .plus)
        XCTAssertEqual((plus.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((plus.rhs as? VariableNode)?.name, "y")
    }
}
