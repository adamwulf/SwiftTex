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
        let interpreter = Interpreter()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? LetNode)
        XCTAssertNotNil(ast.last as? CallNode)

        guard let first = ast.first, let last = ast.last else { XCTFail(); return }

        let result1 = first.accept(visitor: interpreter)

        guard case .success = result1 else { XCTFail(); return }

        let result2 = last.accept(visitor: interpreter)

        guard
            case .failure(let error) = result2,
            case InterpreterError.IncorrectArgumentCount = error
        else { XCTFail(); return }
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

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? LetNode)
        XCTAssertNotNil(ast.last as? CallNode)

        guard let first = ast.first, let last = ast.last else { XCTFail(); return }

        let result1 = first.accept(visitor: interpreter)

        guard case .success = result1 else { XCTFail(); return }

        let result2 = last.accept(visitor: interpreter)

        guard case .success(let result) = result2 else { XCTFail(); return }
        guard let result = result as? NumberNode else { XCTFail(); return }

        XCTAssertEqual(result.value, 16)
    }

    func testApplyFunction2() throws {
        let source = """
                     \\func
                     { f(x) }
                     { x^2 }
                     \\func
                     { g(x) }
                     { x + 7 }

                     f(g(3))
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()
        let interpreter = Interpreter()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? LetNode)
        XCTAssertNotNil(ast[1] as? LetNode)
        XCTAssertNotNil(ast.last as? CallNode)

        guard
            let first = ast.first,
            case let second = ast[1],
            let last = ast.last
        else { XCTFail(); return }

        let result1 = first.accept(visitor: interpreter)
        guard case .success = result1 else { XCTFail(); return }

        let result2 = second.accept(visitor: interpreter)
        guard case .success = result2 else { XCTFail(); return }

        let result3 = last.accept(visitor: interpreter)

        guard case .success(let result) = result3 else { XCTFail(); return }
        guard let result = result as? NumberNode else { XCTFail(); return }

        XCTAssertEqual(result.value, 100)
    }

    func testApplyFunction3() throws {
        let source = """
                     \\func
                     { f(x) }
                     { x^2 }
                     \\func
                     { g(x) }
                     { x + 7 }

                     f(g(x))
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()
        let interpreter = Interpreter()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? LetNode)
        XCTAssertNotNil(ast[1] as? LetNode)
        XCTAssertNotNil(ast.last as? CallNode)

        guard
            let first = ast.first,
            case let second = ast[1],
            let last = ast.last
        else { XCTFail(); return }

        let result1 = first.accept(visitor: interpreter)
        guard case .success = result1 else { XCTFail(); return }

        let result2 = second.accept(visitor: interpreter)
        guard case .success = result2 else { XCTFail(); return }

        let result3 = last.accept(visitor: interpreter)

        guard case .success(let result) = result3 else { XCTFail(); return }
        guard let result = result as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(result.asTex, "(x + 7) ^ 2")
    }

    func testApplyFunction4() throws {
        let source = """
                     \\func
                     { f(x) }
                     { x^2 }

                     f(x + 7)
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()
        let interpreter = Interpreter()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? LetNode)
        XCTAssertNotNil(ast.last as? CallNode)

        guard
            let first = ast.first,
            let last = ast.last
        else { XCTFail(); return }

        let result1 = first.accept(visitor: interpreter)
        guard case .success = result1 else { XCTFail(); return }

        let result2 = last.accept(visitor: interpreter)

        guard case .success(let result) = result2 else { XCTFail(); return }
        guard let result = result as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(result.asTex, "(x + 7) ^ 2")
    }

    func testApplyFunction5() throws {
        let source = """
                     \\let
                     { x }
                     { 5 }

                     \\func
                     { f(x) }
                     { x^2 }

                     f(x + 7)
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()
        let interpreter = Interpreter()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? LetNode)
        XCTAssertNotNil(ast[1] as? LetNode)
        XCTAssertNotNil(ast.last as? CallNode)

        guard
            let first = ast.first,
            case let second = ast[1],
            let last = ast.last
        else { XCTFail(); return }

        let result1 = first.accept(visitor: interpreter)
        guard case .success = result1 else { XCTFail(); return }

        let result2 = second.accept(visitor: interpreter)
        guard case .success = result2 else { XCTFail(); return }

        let result3 = last.accept(visitor: interpreter)

        guard case .success(let result) = result3 else { XCTFail(); return }
        guard let result = result as? NumberNode else { XCTFail(); return }

        XCTAssertEqual(result.asTex, "144")
    }

    func testCurryFunction1() throws {
        let source = """
                     \\func{ f(x, y) }{ x + y }

                     \\let { g }{ f(2) }

                     g(5)
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()
        let interpreter = Interpreter()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? LetNode)
        XCTAssertNotNil(ast[1] as? LetNode)
        XCTAssertNotNil(ast.last as? CallNode)

        guard
            let first = ast.first,
            case let second = ast[1],
            let last = ast.last
        else { XCTFail(); return }

        let result1 = first.accept(visitor: interpreter)
        guard case .success = result1 else { XCTFail(); return }

        let result2 = second.accept(visitor: interpreter)
        guard case .success = result2 else { XCTFail(); return }

        let result3 = last.accept(visitor: interpreter)

        guard case .success(let result1) = result1 else { XCTFail(); return }
        guard case .success(let result2) = result2 else { XCTFail(); return }
        guard case .success(let result3) = result3 else { XCTFail(); return }

        guard result1 as? NumberNode != nil else { XCTFail(); return }
        guard result2 as? NumberNode != nil else { XCTFail(); return }
        guard result3 as? NumberNode != nil else { XCTFail(); return }

        XCTAssertEqual(result2.asTex, "\\let { g }{ f(2) }")
        XCTAssertEqual(result3.asTex, "7")
    }

    func testCurryFunction2() throws {
        let source = """
                     \\func{ f(x, y, z) }{ x + y + z }

                     \\let { g }{ f(2) }

                     g(5, 2)

                     f(2)(5, 2)
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()
        let interpreter = Interpreter()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? LetNode)
        XCTAssertNotNil(ast[1] as? LetNode)
        XCTAssertNotNil(ast.last as? CallNode)

        guard
            let first = ast.first,
            case let second = ast[1],
            let last = ast.last
        else { XCTFail(); return }

        let result1 = first.accept(visitor: interpreter)
        guard case .success = result1 else { XCTFail(); return }

        let result2 = second.accept(visitor: interpreter)
        guard case .success = result2 else { XCTFail(); return }

        let result3 = last.accept(visitor: interpreter)

        guard case .success(let result1) = result1 else { XCTFail(); return }
        guard case .success(let result2) = result2 else { XCTFail(); return }
        guard case .success(let result3) = result3 else { XCTFail(); return }

        guard result1 as? NumberNode != nil else { XCTFail(); return }
        guard result2 as? NumberNode != nil else { XCTFail(); return }
        guard result3 as? NumberNode != nil else { XCTFail(); return }

        XCTAssertEqual(result2.asTex, "\\let { g }{ f(2) }")
        XCTAssertEqual(result3.asTex, "7")
    }

    func testCurryFunction1_1() throws {
        let source = """
                     \\func{ f(x, y) }{ x + y }

                     \\let { g }{ f(2) }

                     g(5)
                     """
        let results = Runtime.run(source: source)

        guard case .success(let result1) = results[0] else { XCTFail(); return }
        guard case .success(let result2) = results[1] else { XCTFail(); return }
        guard case .success(let result3) = results[2] else { XCTFail(); return }

        guard result1.evaluated as? LetNode != nil else { XCTFail(); return }
        guard result2.evaluated as? LetNode != nil else { XCTFail(); return }
        guard result3.evaluated as? NumberNode != nil else { XCTFail(); return }

        _ = result2.evaluated.asTex

        XCTAssertEqual(result2.evaluated.asTex, "g(y) = 2 + y")
        XCTAssertEqual(result3.evaluated.asTex, "7")
    }
}
