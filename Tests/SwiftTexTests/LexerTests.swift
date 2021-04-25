//
//  LexerTests.swift
//  
//
//  Created by Adam Wulf on 4/25/21.
//

import XCTest
#if canImport(SwiftTexMac)
@testable import SwiftTexMac
#endif
#if canImport(SwiftTex)
@testable import SwiftTex
#endif

class LexerTests: XCTestCase {

    func testTokens() throws {
        let source = """
                     x + y

                     z * h
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()

        XCTAssertEqual(tokens[0].line, 1)
        XCTAssertEqual(tokens[1].line, 1)
        XCTAssertEqual(tokens[2].line, 1)
        XCTAssertEqual(tokens[3].line, 1)
        XCTAssertEqual(tokens[4].line, 3)
        XCTAssertEqual(tokens[5].line, 3)
        XCTAssertEqual(tokens[6].line, 3)

        XCTAssertEqual(tokens[0].col, 0)
        XCTAssertEqual(tokens[1].col, 2)
        XCTAssertEqual(tokens[2].col, 4)
        XCTAssertEqual(tokens[3].col, 5)
        XCTAssertEqual(tokens[4].col, 0)
        XCTAssertEqual(tokens[5].col, 2)
        XCTAssertEqual(tokens[6].col, 4)

        XCTAssertEqual(tokens[0].loc, 0)
        XCTAssertEqual(tokens[1].loc, 2)
        XCTAssertEqual(tokens[2].loc, 4)
        XCTAssertEqual(tokens[3].loc, 5)
        XCTAssertEqual(tokens[4].loc, 7)
        XCTAssertEqual(tokens[5].loc, 9)
        XCTAssertEqual(tokens[6].loc, 11)
    }

    func testTokens2() throws {
        let source = """
                     x + y\\\\
                     z * h
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()

        XCTAssertEqual(tokens[0].line, 1)
        XCTAssertEqual(tokens[1].line, 1)
        XCTAssertEqual(tokens[2].line, 1)
        XCTAssertEqual(tokens[3].line, 1)
        XCTAssertEqual(tokens[4].line, 2)
        XCTAssertEqual(tokens[5].line, 2)
        XCTAssertEqual(tokens[6].line, 2)

        XCTAssertEqual(tokens[0].col, 0)
        XCTAssertEqual(tokens[1].col, 2)
        XCTAssertEqual(tokens[2].col, 4)
        XCTAssertEqual(tokens[3].col, 5)
        XCTAssertEqual(tokens[4].col, 0)
        XCTAssertEqual(tokens[5].col, 2)
        XCTAssertEqual(tokens[6].col, 4)

        XCTAssertEqual(tokens[0].loc, 0)
        XCTAssertEqual(tokens[1].loc, 2)
        XCTAssertEqual(tokens[2].loc, 4)
        XCTAssertEqual(tokens[3].loc, 5)
        XCTAssertEqual(tokens[4].loc, 8)
        XCTAssertEqual(tokens[5].loc, 10)
        XCTAssertEqual(tokens[6].loc, 12)
    }

    func testLineSplitter() throws {
        let source = """
                     This is an % stupid
                     % Better: instructive <----
                     example Supercal%
                     ifragilist%
                     icexpialidocious
                     """
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        XCTAssert(errors.isEmpty)
        XCTAssertNotNil(ast)
        XCTAssertEqual(tokens.count, 5)
        XCTAssertEqual(tokens.last!.raw, "Supercalifragilisticexpialidocious")
    }

    func testCommentAffectingTokenLocation() throws {
        let source = """
                     x + y
                     % comment
                     x + 7
                     """
        let lexer = Lexer(input: source)
        let (tokens, comments) = lexer.tokenize()
        let parser = Parser(tokens: tokens)
        let (expressions: ast, errors: errors) = try parser.parse()

        guard comments.count == 1 else { XCTFail("wrong comment count"); return }
        XCTAssertEqual(comments[0].raw, "% comment\n")
        XCTAssertEqual(comments[0].line, 2)
        XCTAssertEqual(comments[0].col, 0)
        XCTAssertEqual(comments[0].loc, 6)
        XCTAssertEqual(comments[0].tail, 0)

        guard tokens.count == 6 else { XCTFail("wrong token count"); return }
        XCTAssertNotNil(tokens[0].type == .Identifier("x"))
        XCTAssertNotNil(tokens[1].type == .Operator(.plus))
        XCTAssertNotNil(tokens[2].type == .Identifier("y"))
        XCTAssertNotNil(tokens[3].type == .Identifier("x"))
        XCTAssertNotNil(tokens[4].type == .Operator(.plus))
        XCTAssertNotNil(tokens[5].type == .Number("7"))

        XCTAssertEqual(errors.count, 0)
        XCTAssertEqual(ast.count, 1)

        XCTAssertEqual(tokens[0].line, 1)
        XCTAssertEqual(tokens[0].col, 0)
        XCTAssertEqual(tokens[0].loc, 0)

        XCTAssertEqual(tokens[3].line, 3)
        XCTAssertEqual(tokens[3].col, 0)
        XCTAssertEqual(tokens[3].loc, 16)
    }

    func testCommentWithTailAffectingTokenLocation() throws {
        let source = """
                     x + y
                     % comment
                        x & 7
                     """
        let lexer = Lexer(input: source)
        let (tokens, comments) = lexer.tokenize()

        guard comments.count == 1 else { XCTFail("wrong comment count"); return }
        XCTAssertEqual(comments[0].raw, "% comment\n   ")
        XCTAssertEqual(comments[0].line, 2)
        XCTAssertEqual(comments[0].col, 0)
        XCTAssertEqual(comments[0].loc, 6)
        XCTAssertEqual(comments[0].tail, 3)

        guard tokens.count == 6 else { XCTFail("wrong token count"); return }
        XCTAssertNotNil(tokens[0].type == .Identifier("x"))
        XCTAssertNotNil(tokens[1].type == .Operator(.plus))
        XCTAssertNotNil(tokens[2].type == .Identifier("y"))
        XCTAssertNotNil(tokens[3].type == .Identifier("x"))
        XCTAssertNotNil(tokens[4].type == .Other("&"))
        XCTAssertNotNil(tokens[5].type == .Number("7"))

        XCTAssertEqual(tokens[0].line, 1)
        XCTAssertEqual(tokens[0].col, 0)
        XCTAssertEqual(tokens[0].loc, 0)

        XCTAssertEqual(tokens[3].line, 3)
        XCTAssertEqual(tokens[3].col, 3)
        XCTAssertEqual(tokens[3].loc, 19)

        XCTAssertEqual(tokens[4].line, 3)
        XCTAssertEqual(tokens[4].col, 5)
        XCTAssertEqual(tokens[4].loc, 21)
    }

    func testAdjacentComments() throws {
        let source = """
                     x + y
                     % comment % comment
                        % comment
                        x & 7
                     """
        let lexer = Lexer(input: source)
        let (tokens, comments) = lexer.tokenize()

        guard comments.count == 2 else { XCTFail("wrong comment count"); return }
        XCTAssertEqual(comments[0].raw, "% comment % comment\n   ")
        XCTAssertEqual(comments[0].line, 2)
        XCTAssertEqual(comments[0].col, 0)
        XCTAssertEqual(comments[0].loc, 6)
        XCTAssertEqual(comments[0].tail, 3)

        XCTAssertEqual(comments[1].raw, "% comment\n   ")
        XCTAssertEqual(comments[1].line, 3)
        XCTAssertEqual(comments[1].col, 3)
        XCTAssertEqual(comments[1].loc, 29)
        XCTAssertEqual(comments[1].tail, 3)

        guard tokens.count == 6 else { XCTFail("wrong token count"); return }
        XCTAssertNotNil(tokens[0].type == .Identifier("x"))
        XCTAssertNotNil(tokens[1].type == .Operator(.plus))
        XCTAssertNotNil(tokens[2].type == .Identifier("y"))
        XCTAssertNotNil(tokens[3].type == .Identifier("x"))
        XCTAssertNotNil(tokens[4].type == .Other("&"))
        XCTAssertNotNil(tokens[5].type == .Number("7"))

        XCTAssertEqual(tokens[0].line, 1)
        XCTAssertEqual(tokens[0].col, 0)
        XCTAssertEqual(tokens[0].loc, 0)

        XCTAssertEqual(tokens[3].line, 4)
        XCTAssertEqual(tokens[3].col, 3)
        XCTAssertEqual(tokens[3].loc, 42)

        XCTAssertEqual(tokens[4].line, 4)
        XCTAssertEqual(tokens[4].col, 5)
        XCTAssertEqual(tokens[4].loc, 44)
    }
}
