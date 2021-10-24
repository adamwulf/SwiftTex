//
//  InterpreterTests.swift
//  
//
//  Created by Adam Wulf on 10/24/21.
//

import Foundation

import XCTest
#if canImport(SwiftTexMac)
@testable import SwiftTexMac
#endif
#if canImport(SwiftTex)
@testable import SwiftTex
#endif

class InterpreterTests: XCTestCase {
    func testSimpleFoil() throws {
        let source = "(x + 1)(x + 2)"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: _) = try parser.parse()
        let foilVisitor = Interpreter()
        let printVisitor = PrintVisitor()

        let ret = ast.first!.accept(visitor: foilVisitor)

        switch ret {
        case .success(let val):
            XCTAssertEqual(val.accept(visitor: printVisitor), "(x + 1)(x + 2)")
        case .failure(_):
            XCTFail()
        }
    }

    func testSimpleFoil2() throws {
        let source = "(4 + 1)(x + 2)"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: _) = try parser.parse()
        let interpreter = Interpreter()
        let printVisitor = PrintVisitor()

        let ret = ast.first!.accept(visitor: interpreter)

        switch ret {
        case .success(let val):
            XCTAssertEqual(val.accept(visitor: printVisitor), "5(x + 2)")
        case .failure(_):
            XCTFail()
        }
    }
}
