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
        XCTAssertEqual(str, "p - 2 p + p")
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
        XCTAssertEqual(str, "p_{0 x} - 2 p_{1 x} + p_{2 x}")
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
}
