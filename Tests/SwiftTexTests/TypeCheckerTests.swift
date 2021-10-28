//
//  File.swift
//  
//
//  Created by Adam Wulf on 10/27/21.
//

import Foundation
import XCTest
#if canImport(SwiftTexMac)
@testable import SwiftTexMac
#endif
#if canImport(SwiftTex)
@testable import SwiftTex
#endif

class TypeCheckerTests: XCTestCase {
    func testCantSimplify() throws {
        let source = "(x + 1)(x + 2)"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: _) = try parser.parse()
        let typeChecker = TypeChecker()
        let printVisitor = PrintVisitor()

        let ret = ast.first!.accept(visitor: typeChecker)

        switch ret {
        case .success(let val):
            switch val {
            case .number(let node):
                XCTAssertEqual(node.accept(visitor: printVisitor), source)
            default:
                XCTFail()
            }
        case .failure(_):
            XCTFail()
        }
    }

    func testBinaryUnary() throws {
        let source = "2 * -100"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: _) = try parser.parse()
        let typeChecker = TypeChecker()
        let printVisitor = PrintVisitor()

        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let mult = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(mult.op, .mult(implicit: false))

        let ret = ast.first!.accept(visitor: typeChecker)

        switch ret {
        case .success(let val):
            switch val {
            case .number(let node):
                XCTAssertEqual(node.accept(visitor: printVisitor), source)
            default:
                XCTFail()
            }
        case .failure(_):
            XCTFail()
        }
    }

    func testApplyFunctionTooManyArgs() throws {
        let source = """
                     \\func
                     { f(x) }
                     { x^2 }

                     f(4, 4)
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()
        let typeChecker = TypeChecker()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? FunctionNode)
        XCTAssertNotNil(ast.last as? CallNode)

        guard let first = ast.first, let last = ast.last else { XCTFail(); return }

        let result1 = first.accept(visitor: typeChecker)

        guard case .success = result1 else { XCTFail(); return }

        let result2 = last.accept(visitor: typeChecker)

        guard
            case .failure(let error) = result2,
            case TypeCheckerError.InvalidArgumentCount = error
        else { XCTFail(); return }
    }
}
