//
//  Lexer.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

public struct Comment {
    public let line: Int
    public let col: Int
    public let loc: Int
    public let length: Int
    public let raw: String
    // the number of characters of whitespace on the last line of the comment
    let tail: Int
}

public struct Token {
    public enum Symbol {
        case plus
        case minus
        case mult(implicit: Bool = false)
        case div
        case exp
        case equal

        static func from(_ str: String) -> Symbol? {
            switch str {
            case "+":
                return Symbol.plus
            case "-":
                return Symbol.minus
            case "*":
                return Symbol.mult(implicit: false)
            case " ":
                return Symbol.mult(implicit: true)
            case "/":
                return Symbol.div
            case "^":
                return Symbol.exp
            case "=":
                return Symbol.equal
            default:
                return nil
            }
        }

        public var isUnary: Bool {
            switch self {
            case .plus, .minus:
                return true
            default:
                return false
            }
        }

        public var isBinary: Bool {
            return true
        }

        public var rawValue: String {
            switch self {
            case .plus:
                return "+"
            case .minus:
                return "-"
            case let .mult(implicit):
                return implicit ? " " : "*"
            case .div:
                return "/"
            case .exp:
                return "^"
            case .equal:
                return "="
            }
        }
    }

    public enum Case {
        case Tex(String)
        case Identifier(String)
        case Number(String)
        case ParensOpen
        case ParensClose
        case BraceOpen
        case BraceClose
        case Subscript
        case Comma
        case Operator(Symbol)
        case Other(String)
        case EOF
        case EOL
    }

    public let type: Case
    public let line: Int
    public let col: Int
    public let loc: Int
    public let raw: String
}

typealias TokenGenerator = (String, Int, Int, Int) -> Token?
let tokenList: [(String, TokenGenerator)] = [
    ("\n\n", { s, l, c, loc in Token(type: .EOL, line: l, col: c, loc: loc, raw: s) }),
    ("\\\\\\\\", { s, l, c, loc in Token(type: .EOL, line: l, col: c, loc: loc, raw: s) }),
    ("[ \t]", { _, _, _, _ in nil }),
    ("[\n]", { _, _, _, _ in nil }), // separate out into its own match so that we always move by a single character for newlines
    ("\\\\[a-zA-Z]+", { s, l, c, loc in Token(type: .Tex(s), line: l, col: c, loc: loc, raw: s) }),
    ("[a-zA-Z]+", { s, l, c, loc in Token(type: .Identifier(s), line: l, col: c, loc: loc, raw: s) }),
    ("[0-9]+\\.?[0-9]*", { s, l, c, loc in Token(type: .Number(s), line: l, col: c, loc: loc, raw: s) }),
    ("\\(", { s, l, c, loc in Token(type: .ParensOpen, line: l, col: c, loc: loc, raw: s) }),
    ("\\)", { s, l, c, loc in Token(type: .ParensClose, line: l, col: c, loc: loc, raw: s) }),
    ("\\{", { s, l, c, loc in Token(type: .BraceOpen, line: l, col: c, loc: loc, raw: s) }),
    ("\\}", { s, l, c, loc in Token(type: .BraceClose, line: l, col: c, loc: loc, raw: s) }),
    ("_", { s, l, c, loc in Token(type: .Subscript, line: l, col: c, loc: loc, raw: s) }),
    (",", { s, l, c, loc in Token(type: .Comma, line: l, col: c, loc: loc, raw: s) }),
    ("[\\+\\-\\*/\\^=]", { s, l, c, loc in Token(type: .Operator(Token.Symbol.from(s)!), line: l, col: c, loc: loc, raw: s) })
]

public class Lexer {
    let input: String
    public init(input: String) {
        self.input = input
    }
    public func tokenize() -> (tokens: [Token], comments: [Comment]) {
        var tokens: [Token] = []
        var content = input
        var line = 1
        var col = 0
        var loc = 0

        // find all of the comments and store their location information
        var comments: [Comment] = []
        for commentMatch in input.matches(regex: "%[^\n]*[ \t\n]*", mustStart: false) {
            let prefix = { () -> (string: String, length: Int, lines: Int, tail: Int) in
                let string = String(content.prefix(upTo: commentMatch.range.lowerBound))
                let lineCount = string.components(separatedBy: "\n").count
                let tail: Int
                if let index = string.lastIndex(of: "\n") {
                    tail = string.suffix(from: index).utf8.count - 1
                } else {
                    tail = string.utf8.count
                }

                return (string: string, length: string.utf8.count, lines: lineCount, tail: tail)
            }()

            let comment = commentMatch.str
            let line = prefix.lines
            let col = prefix.tail
            let loc = prefix.length
            let tail = { () -> Int in
                guard let li = comment.lastIndex(of: "\n") else { return 0 }
                return comment.suffix(from: li).utf8.count - 1 // don't count the \n itself
            }()
            comments.append(Comment(line: line, col: col, loc: loc, length: comment.utf8.count, raw: comment, tail: tail))
        }

        // strip comments out of actual parsed content
        while let (_, nsrange, _) = content.match(regex: "%[^\n]*[ \t\n]*", mustStart: false) {
            content = (content as NSString).replacingCharacters(in: nsrange, with: "")
        }

        while content.lengthOfBytes(using: .utf8) > 0 {
            var matched = false

            for (pattern, generator) in tokenList {
                if let (m, _, _) = content.match(regex: pattern, mustStart: true) {
                    if let t = generator(m, line, col, loc) {
                        tokens.append(t)
                    }
                    let endIndex = content.index(content.startIndex, offsetBy: m.lengthOfBytes(using: .utf8))

                    col += m.lengthOfBytes(using: .utf8)
                    loc += m.lengthOfBytes(using: .utf8)

                    content = String(content[endIndex...])
                    matched = true

                    if case let resetLines = m.components(separatedBy: "\n").count - 1,
                       let index = m.lastIndex(of: "\n"),
                       resetLines > 0 {
                        line += resetLines
                        col = m.suffix(from: index).utf8.count - 1
                    }
                    break
                }
            }

            if !matched {
                let index = content.index(after: content.startIndex)
                let str = String(content[..<index])
                tokens.append(Token(type: .Other(str), line: line, col: col, loc: loc, raw: str))
                content = String(content[index...])

                col += 1
            }
        }
        return (tokens: tokens, comments: comments)
    }
}
