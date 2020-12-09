//
//  FoilTests.swift
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

class FoilTests: XCTestCase {
    func testSimpleFoil() throws {
        let source = multiline(
            "(x + 1)(x + 2)"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let foilVisitor = FoilVisitor()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: foilVisitor).accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "xx + x2 + 1x + (1)(2)")
    }

    func testSimpleFoilSteps() throws {
        let source = multiline(
            "(x + 1)(x + 2)"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let foilVisitor = FoilVisitor()
        foilVisitor.singleStep = true
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: foilVisitor).accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "x(x + 2) + 1(x + 2)")
    }

    func testExpandingExponents() throws {
        let source = multiline(
            "(x + y)^0"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()
        let foilVisitor = FoilVisitor()

        var str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "(x + y) ^ 0")

        str = ast.last!.accept(visitor: foilVisitor).accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "1")
    }

    func testExpandingExponents2() throws {
        let source = multiline(
            "(x + y)^-1"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()
        let foilVisitor = FoilVisitor()

        var str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "(x + y) ^ -1")

        str = ast.last!.accept(visitor: foilVisitor).accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "1 / (x + y)")
    }

    func testExpandingExponents3() throws {
        let source = multiline(
            "(x + y)^-2"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()
        let foilVisitor = FoilVisitor()

        var str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "(x + y) ^ -2")

        str = ast.last!.accept(visitor: foilVisitor).accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "1 / (xx + xy + yx + yy)")
    }

    func testExpandingExponents4() throws {
        let source = multiline(
            "(x + y)^2.5"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()
        let foilVisitor = FoilVisitor()

        var str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "(x + y) ^ 2.5")

        str = ast.last!.accept(visitor: foilVisitor).accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "xx(x + y) ^ 0.5 + xy(x + y) ^ 0.5 + yx(x + y) ^ 0.5 + yy(x + y) ^ 0.5")
    }
}
