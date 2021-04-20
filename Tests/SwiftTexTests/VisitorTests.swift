//
//  VisitorTests.swift
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

class VisitorTests: XCTestCase {

    func testLet() throws {
        let source = "\\let{x}{2/(3+5)}"
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "\\text{let } x = \\frac{2}{3 + 5}")
    }

    func testLetInline() throws {
        let source = "\\let{x}{2/(3+5)}"
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()
        printVisitor.inline = true

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "\\text{let } x = 2 / (3 + 5)")
    }

    func testAnyTex() throws {
        let source = "\\fumble{foo}"
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "\\fumble{foo}")
    }

    func testTexNewline() throws {
        let source = """
x + 7
8 + y
"""

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "x + (7)(8) + y")
    }

    func testTexNewline2() throws {
        let source = """
x + 7\\\\
8 + y
"""

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str1 = ast.first!.accept(visitor: printVisitor)
        let str2 = ast.last!.accept(visitor: printVisitor)

        XCTAssertEqual(ast.count, 2)
        XCTAssertNotNil(str1)
        XCTAssertEqual(str1, "x + 7")
        XCTAssertNotNil(str2)
        XCTAssertEqual(str2, "8 + y")
    }

    func testTexNewline3() throws {
        let source = """
x + 7

8 + y
"""

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str1 = ast.first!.accept(visitor: printVisitor)
        let str2 = ast.last!.accept(visitor: printVisitor)

        XCTAssertEqual(ast.count, 2)
        XCTAssertNotNil(str1)
        XCTAssertEqual(str1, "x + 7")
        XCTAssertNotNil(str2)
        XCTAssertEqual(str2, "8 + y")
    }

    func testTexNewline4() throws {
        let source = """
\\begin{eqnarray}
x + y\\\\
y + z\\\\
z + x\\\\
\\end{eqnarray}
"""
        let result = """
\\begin{eqnarray}\\\\
x + y\\\\
y + z\\\\
z + x\\\\
\\end{eqnarray}
"""
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, result)
    }

    func testTexNewline5() throws {
        let source = """
\\begin{eqnarray}\\\\
x + y\\\\
y + z\\\\
z + x\\\\
\\end{eqnarray}
"""
        let result = """
\\begin{eqnarray}\\\\
x + y\\\\
y + z\\\\
z + x\\\\
\\end{eqnarray}
"""
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, result)
    }

    func testSimpleExpression() throws {
        let source = "7 + x"
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
        let source = "(7 + x) * 4"
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "(7 + x) * 4")
    }

    func testPrintParens2() throws {
        let source = "2^(7x)"
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "2 ^ (7x)")
    }

    func testPrintParens3() throws {
        let source = "(7 * x) + 4"
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "7 * x + 4")
    }

    func testSimpleSwap() throws {
        let source = """
                     7 + x

                     7 * 3 + x
                     """
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

    func testTexList() throws {
        let source = """
                     \\begin{list}
                     x + y

                     y + z

                     z + x
                     \\end{list}
                     """
        let result = """
                     \\begin{list}\\\\
                     x + y\\\\
                     y + z\\\\
                     z + x\\\\
                     \\end{list}
                     """

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, result)
    }

    func testTexSubList() throws {
        let source = """
                     \\begin{list}
                     \\begin{inside}
                     x + y

                     y + z

                     z + x
                     \\end{inside}
                     \\end{list}
                     """
        let result = """
                     \\begin{list}\\\\
                     \\begin{inside}\\\\
                     x + y\\\\
                     y + z\\\\
                     z + x\\\\
                     \\end{inside}\\\\
                     \\end{list}
                     """

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, result)
    }

    func testWithSubscripts() throws {
        let source = "p_{0x} - 2p_{1x} + p_{2x}"
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "p_{0x} - 2p_{1x} + p_{2x}")
    }

    func testNumberFormatting() throws {
        let source = "2 + 2.0 + 2.02 + 2.000 + 123"
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        let str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "2 + 2.0 + 2.02 + 2.000 + 123")
    }

    func testFunctionFormatting() throws {
        let source = """
                     \\func{ f(x) }{ x^2 }
                     f(2) + g(3)
                     """
        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()

        var str = ast.first!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "f(x) = x ^ 2")

        str = ast.last!.accept(visitor: printVisitor)

        XCTAssertNotNil(str)
        XCTAssertEqual(str, "f(2) + g3")

        let strs = ast.accept(visitor: printVisitor).joined(separator: "\n\n")

        XCTAssertEqual(strs, "f(x) = x ^ 2\n\nf(2) + g3")
    }

    func testAligned() throws {
        guard
            let url = Bundle.module.url(forResource: "aligned", withExtension: "mtex"),
            let data = FileManager.default.contents(atPath: url.path),
            let source = String(data: data, encoding: .utf8)
        else { XCTFail(); return }

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()
        let str = ast.first!.accept(visitor: printVisitor)
        let out = """
                  \\begin{eqalign}\\\\
                  \\text{let } a_{2} &= p_{0x} - 2p_{1x} + p_{2x}\\\\
                  \\text{let } a_{1} &= 2p_{1x} - 2p_{0x}\\\\
                  \\end{eqalign}
                  """

        XCTAssertEqual(str, out)
    }

    func testUnaligned() throws {
        guard
            let url = Bundle.module.url(forResource: "aligned", withExtension: "mtex"),
            let data = FileManager.default.contents(atPath: url.path),
            let source = String(data: data, encoding: .utf8)?.replacingOccurrences(of: "eqalign", with: "fumble")
        else { XCTFail(); return }

        let lexer = Lexer(input: source)
        let tokens = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let ast = try parser.parse()
        let printVisitor = PrintVisitor()
        let str = ast.first!.accept(visitor: printVisitor)
        let out = """
                  \\begin{fumble}\\\\
                  \\text{let } a_{2} = p_{0x} - 2p_{1x} + p_{2x}\\\\
                  \\text{let } a_{1} = 2p_{1x} - 2p_{0x}\\\\
                  \\end{fumble}
                  """

        XCTAssertEqual(str, out)
    }
}
