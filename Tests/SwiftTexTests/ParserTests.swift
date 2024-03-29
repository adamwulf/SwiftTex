//
//  ParserTests.swift
//  SwiftTexTests
//
//  Created by Adam Wulf on 11/30/20.
//

import XCTest
#if canImport(SwiftTexMac)
@testable import SwiftTexMac
#endif
#if canImport(SwiftTex)
@testable import SwiftTex
#endif

class ParserTests: XCTestCase {

    func testAddition() throws {
        let source = "x + y"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(tokens.count, 3)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .plus)
        XCTAssertEqual((plus.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((plus.rhs as? VariableNode)?.name, "y")
    }

    func testNegation() throws {
        let source = "-y"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(tokens.count, 2)
        XCTAssertNotNil(ast.first as? UnaryOpNode)

        guard let negate = ast.first as? UnaryOpNode else { XCTFail(); return }

        XCTAssertEqual(negate.op, .minus)
        XCTAssertEqual((negate.expression as? VariableNode)?.name, "y")
    }

    func testExponentialNegation() throws {
        let source = "-y^2" // as opposed to (-y)^2
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(tokens.count, 4)
        XCTAssertNotNil(ast.first as? UnaryOpNode)

        guard let negate = ast.first as? UnaryOpNode else { XCTFail(); return }

        XCTAssertEqual(negate.op, .minus)
        XCTAssertEqual((negate.expression as? BinaryOpNode)?.op, .exp)
    }

    func testExponentialParenthetical() throws {
        let source = "(-y)^2" // as opposed to (-y)^2
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(tokens.count, 6)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let pow = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(pow.op, .exp)
        XCTAssertEqual((pow.lhs as? UnaryOpNode)?.op, .minus)
        XCTAssertNotNil(pow.rhs as? NumberNode)
    }

    func testOrderOfOps() throws {
        let source = "x + y * z"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(tokens.count, 5)
        XCTAssertNotNil(ast.first as? BinaryOpNode)
        XCTAssertEqual(ast.count, 1)

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .plus)
    }

    func testOrderOfOps2() throws {
        let source = "x * y + z"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(tokens.count, 5)
        XCTAssertNotNil(ast.first as? BinaryOpNode)
        XCTAssertEqual(ast.count, 1)

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .plus)
    }

    func testParen() throws {
        let source = "(x + y) z"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? BinaryOpNode)
        XCTAssertEqual(ast.count, 1)

        guard let mult = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(mult.op, .mult(implicit: true))

        guard let plus = mult.lhs as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .plus)
    }

    func testParen2() throws {
        let source = "z (x + y)"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? BinaryOpNode)
        XCTAssertEqual(ast.count, 1)

        guard let mult = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(mult.op, .mult(implicit: true))

        guard let plus = mult.rhs as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .plus)
    }

    func testImplicitMultiplication() throws {
        let source = "2p_{1x}"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .mult(implicit: true))
        XCTAssertEqual((plus.lhs as? NumberNode)?.value, 2)
        XCTAssertEqual((plus.rhs as? VariableNode)?.name, "p")
    }

    func testImplicitMultiplication2() throws {
        let source = "p_{0x} - 2p_{1x} + p_{2x}"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .plus)
        XCTAssertEqual((plus.lhs as? BinaryOpNode)?.op, .minus)
        XCTAssertEqual((plus.rhs as? VariableNode)?.name, "p")

        guard let minus = plus.lhs as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(minus.op, .minus)
        XCTAssertEqual((minus.lhs as? VariableNode)?.name, "p")
        XCTAssertEqual((minus.rhs as? BinaryOpNode)?.op, .mult(implicit: true))

        guard let mult = minus.rhs as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(mult.op, .mult(implicit: true))
        XCTAssertEqual((mult.lhs as? NumberNode)?.value, 2)
        XCTAssertEqual((mult.rhs as? VariableNode)?.name, "p")
    }

    func testTex() throws {
        let source = "\\mumble{4}"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? TexNode)
        XCTAssertEqual(ast.count, 1)

        guard let tex = ast.first as? TexNode else { XCTFail(); return }

        XCTAssertEqual(tex.name, "\\mumble")
        XCTAssertNotNil(tex.arguments.first != nil)

        guard let brace = tex.arguments.first else { XCTFail(); return }

        XCTAssertNotNil(brace.children.first as? NumberNode)

        guard let num = brace.children.first as? NumberNode else { XCTFail(); return }

        XCTAssertEqual(num.value, 4)
    }

    func testTex2() throws {
        let source = "\\mumble{4}{3}{2}{1}"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? TexNode)
        XCTAssertEqual(ast.count, 1)

        guard let tex = ast.first as? TexNode else { XCTFail(); return }

        XCTAssertEqual(tex.name, "\\mumble")
        XCTAssertEqual(tex.arguments.count, 4)
    }

    func testTex3() throws {
        let source = "\\mumble{\\text{asdf}}{3}{2}{1}"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? TexNode)
        XCTAssertEqual(ast.count, 1)

        guard let tex = ast.first as? TexNode else { XCTFail(); return }

        XCTAssertEqual(tex.name, "\\mumble")
        XCTAssertEqual(tex.arguments.count, 4)
    }

    func testSubscript() throws {
        let source = "x_2"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? VariableNode)
        XCTAssertEqual(ast.count, 1)

        guard let variable = ast.first as? VariableNode else { XCTFail(); return }

        XCTAssertEqual(variable.name, "x")
        XCTAssertNotNil(variable.subscripts.first as? NumberNode)
    }

    func testSubscript2() throws {
        let source = "x_2y"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
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
        let source = "x_{2y}"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? VariableNode)
        XCTAssertEqual(ast.count, 1)

        guard let variable = ast.first as? VariableNode else { XCTFail(); return }

        XCTAssertEqual(variable.name, "x")
        XCTAssertEqual(variable.subscripts.count, 2)
        XCTAssertNotNil(variable.subscripts.first as? NumberNode)
        XCTAssertNotNil(variable.subscripts.last as? VariableNode)
    }

    func testSubscript4() throws {
        let source = "x_{y}_2"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? VariableNode)
        XCTAssertEqual(ast.count, 1)

        guard let variable = ast.first as? VariableNode else { XCTFail(); return }

        XCTAssertEqual(variable.name, "x")
        XCTAssertEqual(variable.subscripts.count, 2)
        XCTAssertNotNil(variable.subscripts.first as? VariableNode)
        XCTAssertNotNil(variable.subscripts.last as? NumberNode)
    }

    func testParens() throws {
        let source = "(x + 2)(x - 2)"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(ast.count, 1)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let mult = ast.first as? BinaryOpNode else { XCTFail(); return }

        // implied multiplication
        XCTAssertEqual(mult.op, .mult(implicit: true))

        XCTAssertNotNil(mult.lhs as? BinaryOpNode)
        XCTAssertEqual((mult.lhs as? BinaryOpNode)?.op, .plus)

        XCTAssertNotNil(mult.rhs as? BinaryOpNode)
        XCTAssertEqual((mult.rhs as? BinaryOpNode)?.op, .minus)
    }

    func testFraction() throws {
        let source = "\\frac{x + 2}{x - 2}"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(ast.count, 1)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let frac = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(frac.op, .div)
        XCTAssertNotNil(frac.lhs as? BinaryOpNode)
        XCTAssertEqual((frac.lhs as? BinaryOpNode)?.op, .plus)
        XCTAssertNotNil(frac.rhs as? BinaryOpNode)
        XCTAssertEqual((frac.rhs as? BinaryOpNode)?.op, .minus)
    }

    func testExponent() throws {
        let source = "x ^ y"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(tokens.count, 3)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let exp = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(exp.op, .exp)
        XCTAssertEqual((exp.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((exp.rhs as? VariableNode)?.name, "y")
    }

    func testExponent2() throws {
        let source = "x ^ y + 2"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(tokens.count, 5)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .plus)
        XCTAssertNotNil(plus.lhs as? BinaryOpNode)
        XCTAssertEqual((plus.rhs as? NumberNode)?.value, 2)

        guard let exp = plus.lhs as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(exp.op, .exp)
        XCTAssertEqual((exp.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((exp.rhs as? VariableNode)?.name, "y")
    }

    func testExponent3() throws {
        let source = "x ^ y ^ z"
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(tokens.count, 5)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let exp2 = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(exp2.op, .exp)
        XCTAssertNotNil(exp2.lhs as? BinaryOpNode)
        XCTAssertEqual((exp2.rhs as? VariableNode)?.name, "z")

        guard let exp1 = exp2.lhs as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(exp1.op, .exp)
        XCTAssertEqual((exp1.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((exp1.rhs as? VariableNode)?.name, "y")
    }

    func testDefineFunction() throws {
        let source = """
                     \\func{ f(x_1) }{ x_1^2 }
                     f(4)
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? LetNode)

        guard
            let assignment = ast.first as? LetNode,
            let thunk = assignment.value as? ClosureNode
        else { XCTFail(); return }

        XCTAssertEqual(assignment.variable.name, "f")
        XCTAssertEqual(thunk.prototype.argumentNames.count, 1)

        guard let arg1 = thunk.prototype.argumentNames.first else { XCTFail(); return }

        XCTAssertEqual(arg1.name, "x")

        XCTAssertNotNil(thunk.body as? BinaryOpNode)
        guard let body = thunk.body as? BinaryOpNode else { XCTFail(); return }

        XCTAssertNotNil(body.lhs as? VariableNode)
        XCTAssertNotNil(body.rhs as? NumberNode)

        XCTAssertNotNil(ast.last as? CallNode)

        guard let call = ast.last as? CallNode else { XCTFail(); return }

        XCTAssertNotNil(call.callee as? VariableNode)
        XCTAssertEqual((call.callee as? VariableNode)?.name, "f")
        XCTAssertNotNil(call.arguments.first as? NumberNode)
    }

    func testBeginEndTex() throws {
        let source = """
                     \\begin{align}
                     \\func{ f(x_1) }{ x_1^2 }
                     \\func{ f(x_1) }{ x_1^3 }
                     \\end{align}
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? TexListNode)

        guard let texList = ast.first as? TexListNode else { XCTFail(); return }

        XCTAssertEqual(texList.arguments.count, 1)
        XCTAssertEqual(texList.children.count, 2)
    }

    func testMultilineFunc() throws {
        let source = """
                     \\func
                     { f(x_1) }
                     { x_1^2 }
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast.first as? LetNode)

        guard
            let texList = ast.first as? LetNode,
            let thunk = texList.value as? ClosureNode
        else { XCTFail(); return }

        XCTAssertEqual(texList.variable.name, "f")
        XCTAssertEqual(thunk.prototype.argumentNames.count, 1)
        XCTAssertNotNil(thunk.body as? BinaryOpNode)
    }

    func testFileInput() throws {
        guard
            let url = Bundle.module.url(forResource: "simple", withExtension: "mtex"),
            let data = FileManager.default.contents(atPath: url.path),
            let source = String(data: data, encoding: .utf8)
        else { XCTFail(); return }

        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(ast.count, 7)
        XCTAssertNotNil(ast[0] as? LetNode)
        XCTAssertNotNil(ast[1] as? LetNode)
        XCTAssertNotNil(ast[2] as? LetNode)
        XCTAssertNotNil(ast[3] as? LetNode)
        XCTAssertNotNil(ast[4] as? LetNode)
        XCTAssertNotNil(ast[5] as? LetNode)
        XCTAssertNotNil(ast[6] as? LetNode)
    }

    func testFileInput2() throws {
        guard
            let url = Bundle.module.url(forResource: "simple2", withExtension: "mtex"),
            let data = FileManager.default.contents(atPath: url.path),
            let source = String(data: data, encoding: .utf8)
        else { XCTFail(); return }

        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertEqual(ast.count, 6)
        XCTAssertNotNil(ast[0] as? VariableNode)
        XCTAssertNotNil(ast[1] as? VariableNode)
        XCTAssertNotNil(ast[2] as? NumberNode)
        XCTAssertNotNil(ast[3] as? NumberNode)
        XCTAssertNotNil(ast[4] as? UnaryOpNode)
        XCTAssertNotNil(ast[5] as? UnaryOpNode)
    }
}
