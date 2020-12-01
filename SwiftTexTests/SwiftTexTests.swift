//
//  SwiftTexTests.swift
//  SwiftTexTests
//
//  Created by Adam Wulf on 11/30/20.
//

import XCTest
@testable import SwiftTex

class SwiftTexTests: XCTestCase {

    func testAddition() throws {
        let source = multiline(
            "x + y"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertEqual(tokens.count, 3)
        XCTAssertNotNil(ast.first as? BinaryOpNode)
    }

    func testOrderOfOps() throws {
        let source = multiline(
            "x + y * z"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertEqual(tokens.count, 5)
        XCTAssertNotNil(ast.first as? BinaryOpNode)
        XCTAssertEqual(ast.count, 1)

        guard let plus = ast.first as? BinaryOpNode else { return }

        XCTAssertEqual(plus.op, "+")
    }

    func testOrderOfOps2() throws {
        let source = multiline(
            "x * y + z"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertEqual(tokens.count, 5)
        XCTAssertNotNil(ast.first as? BinaryOpNode)
        XCTAssertEqual(ast.count, 1)

        guard let plus = ast.first as? BinaryOpNode else { return }

        XCTAssertEqual(plus.op, "+")
    }

    func testParen() throws {
        let source = multiline(
            "(x + y) z"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let plus = ast.first as? BinaryOpNode else { return }

        XCTAssertEqual(plus.op, "+")
    }

    func testParen2() throws {
        let source = multiline(
            "z (x + y)"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? VariableNode)

        guard let variable = ast.first as? VariableNode else { return }

        XCTAssertEqual(variable.name, "z")
    }

    func testTex() throws {
        let source = multiline(
            "\\frac{4}"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? TexNode)

        guard let tex = ast.first as? TexNode else { return }

        XCTAssertEqual(tex.name, "\\frac")

        XCTAssertNotNil(tex.arguments.first as? NumberNode)

        guard let num = tex.arguments.first as? NumberNode else { return }

        XCTAssertEqual(num.value, 4)
    }
}
