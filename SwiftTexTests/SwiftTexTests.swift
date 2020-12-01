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

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, "+")
        XCTAssertEqual((plus.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((plus.rhs as? VariableNode)?.name, "y")
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

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

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

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

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
        XCTAssertEqual(ast.count, 1)

        guard let mult = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(mult.op, "*")

        guard let plus = mult.lhs as? BinaryOpNode else { XCTFail(); return }

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

        XCTAssertNotNil(ast.first as? BinaryOpNode)
        XCTAssertEqual(ast.count, 1)

        guard let mult = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(mult.op, "*")

        guard let plus = mult.rhs as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, "+")
    }

    func testTex() throws {
        let source = multiline(
            "\\mumble{4}"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? TexNode)
        XCTAssertEqual(ast.count, 1)

        guard let tex = ast.first as? TexNode else { XCTFail(); return }

        XCTAssertEqual(tex.name, "\\mumble")

        XCTAssertNotNil(tex.arguments.first as? BracedNode)

        guard let brace = tex.arguments.first as? BracedNode else { XCTFail(); return }

        XCTAssertNotNil(brace.expressions.first as? NumberNode)
        guard let num = brace.expressions.first as? NumberNode else { XCTFail(); return }

        XCTAssertEqual(num.value, 4)
    }

    func testTex2() throws {
        let source = multiline(
            "\\mumble{4}{3}{2}{1}"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? TexNode)
        XCTAssertEqual(ast.count, 1)

        guard let tex = ast.first as? TexNode else { XCTFail(); return }

        XCTAssertEqual(tex.name, "\\mumble")

        XCTAssertEqual(tex.arguments.count, 4)
    }

    func testTex3() throws {
        let source = multiline(
            "\\mumble{\\text{asdf}}{3}{2}{1}"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? TexNode)
        XCTAssertEqual(ast.count, 1)

        guard let tex = ast.first as? TexNode else { XCTFail(); return }

        XCTAssertEqual(tex.name, "\\mumble")

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

        guard let variable = ast.first as? VariableNode else { XCTFail(); return }

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

        XCTAssertNotNil(ast.first as? BinaryOpNode)
        XCTAssertEqual(ast.count, 1)

        guard let mult = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertNotNil(mult.lhs as? VariableNode)

        guard let x = mult.lhs as? VariableNode else { XCTFail(); return }

        XCTAssertEqual(x.name, "x")

        XCTAssertNotNil(x.subscripts.first as? NumberNode)

        XCTAssertNotNil(mult.rhs as? VariableNode)

        guard let y = mult.rhs as? VariableNode else { XCTFail(); return }

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

        guard let variable = ast.first as? VariableNode else { XCTFail(); return }

        XCTAssertEqual(variable.name, "x")

        XCTAssertNotNil(variable.subscripts.first as? BinaryOpNode)

        guard let sub = variable.subscripts.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertNotNil(sub.lhs as? NumberNode)
        XCTAssertNotNil(sub.rhs as? VariableNode)
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

        guard let variable = ast.first as? VariableNode else { XCTFail(); return }

        XCTAssertEqual(variable.name, "x")

        XCTAssertEqual(variable.subscripts.count, 2)
        XCTAssertNotNil(variable.subscripts.first as? VariableNode)
        XCTAssertNotNil(variable.subscripts.last as? NumberNode)
    }

    func testParens() throws {
        let source = multiline(
            "(x + 2)(x - 2)"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertEqual(ast.count, 1)

        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let mult = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(mult.op, "*")

        XCTAssertNotNil(mult.lhs as? BinaryOpNode)
        XCTAssertEqual((mult.lhs as? BinaryOpNode)?.op, "+")

        XCTAssertNotNil(mult.rhs as? BinaryOpNode)
        XCTAssertEqual((mult.rhs as? BinaryOpNode)?.op, "-")
    }

    func testFraction() throws {
        let source = multiline(
            "\\frac{x + 2}{x - 2}"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertEqual(ast.count, 1)

        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let frac = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(frac.op, "/")
        XCTAssertNotNil(frac.lhs as? BinaryOpNode)
        XCTAssertEqual((frac.lhs as? BinaryOpNode)?.op, "+")
        XCTAssertNotNil(frac.rhs as? BinaryOpNode)
        XCTAssertEqual((frac.rhs as? BinaryOpNode)?.op, "-")
    }

    func testExponent() throws {
        let source = multiline(
            "x ^ y"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertEqual(tokens.count, 3)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let exp = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(exp.op, "^")
        XCTAssertEqual((exp.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((exp.rhs as? VariableNode)?.name, "y")
    }

    func testExponent2() throws {
        let source = multiline(
            "x ^ y + 2"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertEqual(tokens.count, 5)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, "+")
        XCTAssertNotNil(plus.lhs as? BinaryOpNode)
        XCTAssertEqual((plus.rhs as? NumberNode)?.value, 2)

        guard let exp = plus.lhs as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(exp.op, "^")
        XCTAssertEqual((exp.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((exp.rhs as? VariableNode)?.name, "y")
    }

    func testExponent3() throws {
        let source = multiline(
            "x ^ y ^ z"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertEqual(tokens.count, 5)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let exp2 = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(exp2.op, "^")
        XCTAssertNotNil(exp2.lhs as? BinaryOpNode)
        XCTAssertEqual((exp2.rhs as? VariableNode)?.name, "z")

        guard let exp1 = exp2.lhs as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(exp1.op, "^")
        XCTAssertEqual((exp1.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((exp1.rhs as? VariableNode)?.name, "y")
    }

    func testDefineFunction() throws {
        let source = multiline(
            "\\func{ f(x_1) }{ x_1^2 }",
            "f(4)"
        )

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()

        XCTAssertNotNil(ast.first as? FunctionNode)

        guard let thunk = ast.first as? FunctionNode else { XCTFail(); return }

        XCTAssertEqual(thunk.prototype.name.name, "f")
        XCTAssertEqual(thunk.prototype.argumentNames.count, 1)

        guard let arg1 = thunk.prototype.argumentNames.first else { XCTFail(); return }

        XCTAssertEqual(arg1.name, "x")

        XCTAssertNotNil(thunk.body as? BinaryOpNode)
        guard let body = thunk.body as? BinaryOpNode else { XCTFail(); return }

        XCTAssertNotNil(body.lhs as? VariableNode)
        XCTAssertNotNil(body.rhs as? NumberNode)
    }
}
