//
//  VisitorTests.swift
//  SwiftTexTests
//
//  Created by Adam Wulf on 12/6/20.
//

import XCTest
@testable import SwiftTex

class VisitorTests: XCTestCase {

    func testSimpleExpression() throws {
        let source = multiline(
            "7 + x"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "7 + x")
    }

    func testPrintParens() throws {
        let source = multiline(
            "(7 + x) * 4"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "(7 + x) * 4")
    }

    func testSimpleSwap() throws {
        let source = multiline(
            "7 + x",
            "",
            "7 * 3 + x"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let swapVisitor = SwapBinaryVisitor()
        let printVisitor = PrintVisitor()

        var str = ast.first!.accept(visitor: swapVisitor).accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "x + 7")

        str = ast.last!.accept(visitor: swapVisitor).accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "x + 3 * 7")
    }

    func testManyBinaryNodes() throws {
        let source = multiline(
            "p_{0x} - 2p_{1x} + p_{2x}"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "p - (2)(p) + p")
    }

    func testTexList() throws {
        let source = multiline(
            "\\begin{list}",
            "x + y",
            "",
            "y + z",
            "",
            "z + x",
            "\\end{list}"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "\\begin{list}\nx + y\ny + z\nz + x\n\\end{list}")
    }

    func testWithSubscripts() throws {
        let source = multiline(
            "p_{0x} - 2p_{1x} + p_{2x}"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()
        printVisitor.ignoreSubscripts = false

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "p_{0x} - (2)(p_{1x}) + p_{2x}")
    }

    func testNumberFormatting() throws {
        let source = multiline(
            "2 + 2.0 + 2.02 + 2.000 + 123"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()
        printVisitor.ignoreSubscripts = false

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "2 + 2.0 + 2.02 + 2.000 + 123")
    }

    func testFunctionFormatting() throws {
        let source = multiline(
            "\\func{ f(x) }{ x^2 }",
            "f(2) + g(3)"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()
        printVisitor.ignoreSubscripts = false

        var str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "f(x) = x ^ 2")

        str = ast.last!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "f(2) + (g)(3)")

        let strs = ast.accept(visitor: printVisitor).joined(separator: "\n\n")

        XCTAssertEqual(strs, "f(x) = x ^ 2\n\nf(2) + (g)(3)")
    }
}
