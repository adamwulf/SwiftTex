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
        XCTAssertEqual(str, "x * x + x * 2 + 1 * x + 1 * 2")
    }
}
