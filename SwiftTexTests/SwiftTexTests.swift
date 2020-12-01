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
        XCTAssertEqual(ast.count, 2)

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
        XCTAssertEqual(ast.count, 2)

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
        XCTAssertEqual(ast.count, 1)

        guard let tex = ast.first as? TexNode else { return }

        XCTAssertEqual(tex.name, "\\frac")

        XCTAssertNotNil(tex.arguments.first as? BracedNode)

        guard let brace = tex.arguments.first as? BracedNode else { return }

        XCTAssertNotNil(brace.expressions.first as? NumberNode)
        guard let num = brace.expressions.first as? NumberNode else { return }

        XCTAssertEqual(num.value, 4)
    }

    func testTex2() throws {
        let source = multiline(
            "\\frac{4}{3}{2}{1}"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? TexNode)
        XCTAssertEqual(ast.count, 1)

        guard let tex = ast.first as? TexNode else { return }

        XCTAssertEqual(tex.name, "\\frac")

        XCTAssertEqual(tex.arguments.count, 4)
    }

    func testTex3() throws {
        let source = multiline(
            "\\frac{\\text{asdf}}{3}{2}{1}"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? TexNode)
        XCTAssertEqual(ast.count, 1)

        guard let tex = ast.first as? TexNode else { return }

        XCTAssertEqual(tex.name, "\\frac")

        XCTAssertEqual(tex.arguments.count, 4)
    }

    func testSubscript() throws {
        let source = multiline(
            "x_2"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? VariableNode)
        XCTAssertEqual(ast.count, 1)

        guard let variable = ast.first as? VariableNode else { return }

        XCTAssertEqual(variable.name, "x")

        XCTAssertNotNil(variable.subscripts.first as? NumberNode)
    }

    func testSubscript2() throws {
        let source = multiline(
            "x_2y"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? VariableNode)
        XCTAssertEqual(ast.count, 2)

        guard let x = ast.first as? VariableNode else { return }

        XCTAssertEqual(x.name, "x")

        XCTAssertNotNil(x.subscripts.first as? NumberNode)

        guard let y = ast.last as? VariableNode else { return }

        XCTAssertEqual(y.name, "y")
    }

    func testSubscript3() throws {
        let source = multiline(
            "x_{2y}"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? VariableNode)
        XCTAssertEqual(ast.count, 1)

        guard let variable = ast.first as? VariableNode else { return }

        XCTAssertEqual(variable.name, "x")

        XCTAssertNotNil(variable.subscripts.first as? BracedNode)

        guard let sub = ast.first as? BracedNode else { return }

        XCTAssertNotNil(sub.expressions.first as? NumberNode)
        XCTAssertNotNil(sub.expressions.last as? VariableNode)
    }

    func testSubscript4() throws {
        let source = multiline(
            "x_{y}_2"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? VariableNode)
        XCTAssertEqual(ast.count, 1)

        guard let variable = ast.first as? VariableNode else { return }

        XCTAssertEqual(variable.name, "x")

        XCTAssertEqual(variable.subscripts.count, 2)
        XCTAssertNotNil(variable.subscripts.first as? BracedNode)
        XCTAssertNotNil(variable.subscripts.last as? NumberNode)
    }
}
