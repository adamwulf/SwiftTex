//
//  ErrorTests.swift
//  
//
//  Created by Adam Wulf on 4/19/21.
//

import XCTest
#if canImport(SwiftTexMac)
@testable import SwiftTexMac
#endif
#if canImport(SwiftTex)
@testable import SwiftTex
#endif

class ErrorTests: XCTestCase {

    func testAddition() throws {
        let source = """
                     x + * y

                     x + 7
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssertEqual(tokens.count, 8)
        XCTAssertEqual(errors.count, 1)
        if case .UnexpectedToken(let token) = errors.first {
            XCTAssertEqual(token.line, 1)
            XCTAssertEqual(token.col, 4)
            XCTAssertEqual(token.loc, 4)
            XCTAssertEqual(token.raw, tokens[2].raw)
        } else {
            XCTFail()
        }
        XCTAssertEqual(ast.count, 1)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .plus)
        XCTAssertEqual((plus.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((plus.rhs as? NumberNode)?.value, 7)
    }

    func testEndlineLocation() throws {
        let source = """
                     x + y

                     x + * 7
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let endlToken = tokens[3]

        XCTAssertEqual(tokens.count, 8)
        XCTAssertEqual(endlToken.line, 1)
        XCTAssertEqual(endlToken.col, 5)
        XCTAssertEqual(endlToken.loc, 5)

        let nextToken = tokens[4]

        XCTAssertEqual(nextToken.line, 3)
        XCTAssertEqual(nextToken.col, 0)
        XCTAssertEqual(nextToken.loc, 7)
    }

    func testLineWrapLocation() throws {
        let source = """
                     x + y
                     * 7
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let lastToken = tokens[4]

        XCTAssertEqual(tokens.count, 5)
        XCTAssertEqual(lastToken.line, 2)
        XCTAssertEqual(lastToken.col, 2)
        XCTAssertEqual(lastToken.loc, 8)
    }

    func testFailedAfterLinebreak() throws {
        let source = """
                     x + y

                     x + * 7
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssertEqual(tokens.count, 8)
        XCTAssertEqual(errors.count, 1)
        if case .UnexpectedToken(let token) = errors.first {
            XCTAssertEqual(token.line, 3)
            XCTAssertEqual(token.col, 4)
            XCTAssertEqual(token.loc, 11)
            XCTAssertEqual(token.raw, tokens[6].raw)
        } else {
            XCTFail()
        }
        XCTAssertEqual(ast.count, 1)
        XCTAssertNotNil(ast.first as? BinaryOpNode)

        guard let plus = ast.first as? BinaryOpNode else { XCTFail(); return }

        XCTAssertEqual(plus.op, .plus)
        XCTAssertEqual((plus.lhs as? VariableNode)?.name, "x")
        XCTAssertEqual((plus.rhs as? VariableNode)?.name, "y")
    }

    func testSimpleComment() throws {
        let source = """
                     x + y
                     % comment
                     x + * 7
                     """
        let lexer = Lexer(input: source)
        let (tokens, comments) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssertEqual(tokens.count, 7)
        XCTAssertEqual(comments.count, 1)
        XCTAssertNotNil(tokens[0].type == .Identifier("x"))
        XCTAssertNotNil(tokens[1].type == .Operator(.plus))
        XCTAssertNotNil(tokens[2].type == .Identifier("y"))
        XCTAssertNotNil(tokens[3].type == .Identifier("x"))
        XCTAssertNotNil(tokens[4].type == .Operator(.plus))
        XCTAssertNotNil(tokens[5].type == .Operator(.mult()))

        XCTAssertEqual(comments[0].line, 2)
        XCTAssertEqual(comments[0].col, 0)
        XCTAssertEqual(comments[0].loc, 6)
        XCTAssertEqual(comments[0].length, 10)
        XCTAssertEqual(comments[0].raw, "% comment\n")

        XCTAssertEqual(errors.count, 1)
        if case .UnexpectedToken(let token) = errors.first {
            XCTAssertEqual(token.line, 3)
            XCTAssertEqual(token.col, 4)
            XCTAssertEqual(token.loc, 20)
            XCTAssertEqual(token.raw, tokens[5].raw)
        } else {
            XCTFail()
        }
        XCTAssertEqual(ast.count, 0)
    }

    func testNeighborComments() throws {
        let source = """
                     x + y
                     % comment
                       % line two
                     x + * 7
                     """
        let lexer = Lexer(input: source)
        let (tokens, comments) = lexer.tokenize()

        XCTAssertEqual(tokens.count, 7)
        XCTAssertEqual(comments.count, 2)
        XCTAssertNotNil(tokens[0].type == .Identifier("x"))
        XCTAssertNotNil(tokens[1].type == .Operator(.plus))
        XCTAssertNotNil(tokens[2].type == .Identifier("y"))
        XCTAssertNotNil(tokens[3].type == .Identifier("x"))
        XCTAssertNotNil(tokens[4].type == .Operator(.plus))
        XCTAssertNotNil(tokens[5].type == .Operator(.mult()))

        XCTAssertEqual(comments[0].line, 2)
        XCTAssertEqual(comments[0].col, 0)
        XCTAssertEqual(comments[0].loc, 6)
        XCTAssertEqual(comments[0].length, 12)
        XCTAssertEqual(comments[0].raw, "% comment\n  ")

        XCTAssertEqual(comments[1].line, 3)
        XCTAssertEqual(comments[1].col, 2)
        XCTAssertEqual(comments[1].loc, 18)
        XCTAssertEqual(comments[1].length, 11)
        XCTAssertEqual(comments[1].raw, "% line two\n")
    }

    func testCommentTrailingNextLineSpaces() throws {
        let source = """
                     x + y
                     % comment
                        x + * 7
                     """
        let lexer = Lexer(input: source)
        let (tokens, comments) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        guard comments.count == 1 else { XCTFail("wrong comment count"); return }
        XCTAssertEqual(comments[0].raw, "% comment\n   ")
        XCTAssertEqual(comments[0].line, 2)
        XCTAssertEqual(comments[0].col, 0)
        XCTAssertEqual(comments[0].loc, 6)

        guard tokens.count == 7 else { XCTFail("wrong token count"); return }
        XCTAssertNotNil(tokens[0].type == .Identifier("x"))
        XCTAssertNotNil(tokens[1].type == .Operator(.plus))
        XCTAssertNotNil(tokens[2].type == .Identifier("y"))
        XCTAssertNotNil(tokens[3].type == .Identifier("x"))
        XCTAssertNotNil(tokens[4].type == .Operator(.plus))
        XCTAssertNotNil(tokens[5].type == .Operator(.mult()))
        XCTAssertNotNil(tokens[6].type == .Number("7"))

        XCTAssertEqual(errors.count, 1)
        if case .UnexpectedToken(let token) = errors.first {
            XCTAssertEqual(token.line, 3)
            XCTAssertEqual(token.col, 7)
            XCTAssertEqual(token.loc, 23)
            XCTAssertEqual(token.raw, tokens[5].raw)
        } else {
            XCTFail()
        }
        XCTAssertEqual(ast.count, 0)
    }

    func testTwoErrors() throws {
        let source = """
                     \\

                     % comment

                     \\
                     """
        let lexer = Lexer(input: source)
        let (tokens, comments) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        guard comments.count == 1 else { XCTFail("wrong comment count"); return }
        XCTAssertEqual(comments[0].raw, "% comment\n\n")
        XCTAssertEqual(comments[0].line, 3)
        XCTAssertEqual(comments[0].col, 0)
        XCTAssertEqual(comments[0].loc, 3)

        guard tokens.count == 3 else { XCTFail("wrong token count"); return }
        XCTAssertNotNil(tokens[0].type == .Other("\\"))
        XCTAssertNotNil(tokens[1].type == .EOL)
        XCTAssertNotNil(tokens[2].type == .Other("\\"))

        XCTAssertEqual(errors.count, 2)

        if case .ExpectedExpression(let token) = errors.first {
            XCTAssertEqual(token.line, 1)
            XCTAssertEqual(token.col, 0)
            XCTAssertEqual(token.loc, 0)
            XCTAssertEqual(token.raw, tokens[0].raw)
        } else {
            XCTFail()
        }

        if case .ExpectedExpression(let token) = errors.last {
            XCTAssertEqual(token.line, 5)
            XCTAssertEqual(token.col, 0)
            XCTAssertEqual(token.loc, 14)
            XCTAssertEqual(token.raw, tokens[2].raw)
        } else {
            XCTFail()
        }

        XCTAssertEqual(ast.count, 0)
    }

    func testEmoji() throws {
        let source = """
                     4 🌎 8
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()

        XCTAssertEqual(tokens[0].line, 1)
        XCTAssertEqual(tokens[0].col, 0)
        XCTAssertEqual(tokens[0].loc, 0)
        XCTAssertEqual(tokens[0].raw, String(source[tokens[0].range]))

        XCTAssertEqual(tokens[1].line, 1)
        XCTAssertEqual(tokens[1].col, 2)
        XCTAssertEqual(tokens[1].loc, 2)
        XCTAssertEqual(tokens[1].raw, String(source[tokens[1].range]))

        XCTAssertEqual(tokens[2].line, 1)
        XCTAssertEqual(tokens[2].col, 5)
        XCTAssertEqual(tokens[2].loc, 5)
        XCTAssertEqual(tokens[2].raw, String(source[tokens[2].range]))
    }

    func testEmoji2() throws {
        let source = "\\\n\n%🌎\n\n/\n\n\\let{a}{5}\n\na = 4\n\n\n/\n\n🌎\n\n\n\\func{f(x)}{y}\n\n"
        let lexer = Lexer(input: source)
        let (tokens, comments) = lexer.tokenize()

        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual(comments[0].raw, "%🌎\n\n")

        XCTAssertEqual(tokens[0].line, 1)
        XCTAssertEqual(tokens[0].col, 0)
        XCTAssertEqual(tokens[0].loc, 0)
        XCTAssertEqual(tokens[0].raw, String(source[tokens[0].range]))

        XCTAssertEqual(tokens[1].line, 1)
        XCTAssertEqual(tokens[1].col, 1)
        XCTAssertEqual(tokens[1].loc, 1)
        XCTAssertEqual(tokens[1].raw, String(source[tokens[1].range]))

        XCTAssertEqual(tokens[2].line, 5)
        XCTAssertEqual(tokens[2].col, 0)
        XCTAssertEqual(tokens[2].loc, 8)
        XCTAssertEqual(tokens[2].raw, String(source[tokens[2].range]))
    }
}
