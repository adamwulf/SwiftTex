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
    func testCantSimplify() throws {
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

    func testSimplify() throws {
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

    func testNegation() throws {
        let source = "-100"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: _) = try parser.parse()
        let interpreter = Interpreter()

        XCTAssertNotNil(ast.first as? UnaryOpNode)

        guard let negate = ast.first as? UnaryOpNode else { XCTFail(); return }

        XCTAssertEqual(negate.op, .minus)
        XCTAssertEqual((negate.expression as? NumberNode)?.value, 100)

        let ret = ast.first!.accept(visitor: interpreter)

        guard case .success(let val) = ret else { XCTFail(); return }
        guard let val = val as? NumberNode else { XCTFail(); return }

        XCTAssertEqual(val.value, -100)
    }

    func testBinaryUnary() throws {
        let source = "2*-100"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: _) = try parser.parse()
        let interpreter = Interpreter()

        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let mult = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(mult.op, .mult(implicit: false))

        let ret = ast.first!.accept(visitor: interpreter)

        guard case .success(let val) = ret else { XCTFail(); return }
        guard let val = val as? NumberNode else { XCTFail(); return }

        XCTAssertEqual(val.value, -200)
    }

    func testApplyFunction() throws {
        let source = """
                     \\func
                     { f(x) }
                     { x^2 }

                     f(4)
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()
        let interpreter = Interpreter()
        let printer = PrintVisitor()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? FunctionNode)
        XCTAssertNotNil(ast.last as? CallNode)

        var results: [ExprNode] = []
        for expr in ast {
            guard case .success(let result) = expr.accept(visitor: interpreter) else { XCTFail(); return }
            results.append(result)
        }

        for (key, val) in interpreter.environment {
            print("\(key.accept(visitor: printer)) => \(val.accept(visitor: printer))")
        }

        guard let result = ast.last as? NumberNode else { XCTFail(); return }
        XCTAssertEqual(result.value, 16)
    }

}
