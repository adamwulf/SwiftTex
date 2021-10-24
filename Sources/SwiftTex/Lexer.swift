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

public struct Token: Equatable {
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
    public let range: Range<String.Index>
    public let line: Int
    public let col: Int
    public let loc: Int
    public let raw: String
}

typealias TokenGenerator = (String, Range<String.Index>, Int, Int, Int) -> Token?
let tokenList: [(String, TokenGenerator)] = [
    ("\n\n", { s, r, l, c, loc in Token(type: .EOL, range: r, line: l, col: c, loc: loc, raw: s) }),
    ("\\\\\\\\", { s, r, l, c, loc in Token(type: .EOL, range: r, line: l, col: c, loc: loc, raw: s) }),
    ("[ \t]", { _, _, _, _, _ in nil }),
    ("[\n]", { _, _, _, _, _ in nil }), // separate out into its own match so that we always move by a single character for newlines
    ("\\\\[a-zA-Z]+", { s, r, l, c, loc in Token(type: .Tex(s), range: r, line: l, col: c, loc: loc, raw: s) }),
    ("[a-zA-Z]+", { s, r, l, c, loc in Token(type: .Identifier(s), range: r, line: l, col: c, loc: loc, raw: s) }),
    ("[0-9]+\\.?[0-9]*", { s, r, l, c, loc in Token(type: .Number(s), range: r, line: l, col: c, loc: loc, raw: s) }),
    ("\\(", { s, r, l, c, loc in Token(type: .ParensOpen, range: r, line: l, col: c, loc: loc, raw: s) }),
    ("\\)", { s, r, l, c, loc in Token(type: .ParensClose, range: r, line: l, col: c, loc: loc, raw: s) }),
    ("\\{", { s, r, l, c, loc in Token(type: .BraceOpen, range: r, line: l, col: c, loc: loc, raw: s) }),
    ("\\}", { s, r, l, c, loc in Token(type: .BraceClose, range: r, line: l, col: c, loc: loc, raw: s) }),
    ("_", { s, r, l, c, loc in Token(type: .Subscript, range: r, line: l, col: c, loc: loc, raw: s) }),
    (",", { s, r, l, c, loc in Token(type: .Comma, range: r, line: l, col: c, loc: loc, raw: s) }),
    ("[\\+\\-\\*/\\^=]", { s, r, l, c, loc in Token(type: .Operator(Token.Symbol.from(s)!), range: r, line: l, col: c, loc: loc, raw: s) })
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
        var mutComments: [Comment] = []
        for commentMatch in input.matches(regex: "%[^\n]*[ \t\n]*", mustStart: false) {
            let nsRange = NSRange(commentMatch.range, in: input)
            let prefix = { () -> (string: String, length: Int, lines: Int, tail: Int) in
                let string = String(content.prefix(upTo: commentMatch.range.lowerBound))
                let lineCount = string.countOccurrences(of: "\n") + 1
                let tail: Int
                if let index = string.lastIndex(of: "\n") {
                    tail = string.suffix(from: index).utf8.count - 1
                } else {
                    tail = nsRange.length
                }

                let prefixRange = ..<commentMatch.range.lowerBound
                let prefixNSRange = NSRange(prefixRange, in: content)

                return (string: string, length: prefixNSRange.length, lines: lineCount, tail: tail)
            }()

            let comment = commentMatch.str
            let line = prefix.lines
            let col = prefix.tail
            let loc = prefix.length
            let tail = { () -> Int in
                guard let li = comment.lastIndex(of: "\n") else { return 0 }
                return comment.suffix(from: li).utf8.count - 1 // don't count the \n itself
            }()
            mutComments.append(Comment(line: line, col: col, loc: loc, length: nsRange.length, raw: comment, tail: tail))
        }

        let comments = mutComments

        // strip comments out of actual parsed content
        while let (_, nsrange, _) = content.match(regex: "%[^\n]*[ \t\n]*", mustStart: false) {
            content = (content as NSString).replacingCharacters(in: nsrange, with: "")
        }

        while content.lengthOfBytes(using: .utf8) > 0 {
            var matched = false

            func adjustForComments() {
                while
                    let comment = mutComments.first,
                    comment.loc <= loc {
                    line += comment.raw.countOccurrences(of: "\n")
                    col = comment.tail
                    loc += comment.length
                    mutComments.removeFirst()
                }
            }

            for (pattern, generator) in tokenList {
                if let (m, contentNSRange, _) = content.match(regex: pattern, mustStart: true) {
                    let inputNSRange = NSRange(location: contentNSRange.location + loc, length: contentNSRange.length)
                    guard let contentRange = Range(contentNSRange, in: content) else { fatalError("invalid range") }
                    guard let inputRange = Range(inputNSRange, in: input) else { fatalError("invalid range") }

                    if let t = generator(m, inputRange, line, col, loc) {
                        tokens.append(t)
                    }

                    col += contentNSRange.length
                    loc += contentNSRange.length

                    content = String(content[contentRange.upperBound...])
                    matched = true

                    if case let resetLines = m.countOccurrences(of: "\n"),
                       let index = m.lastIndex(of: "\n"),
                       resetLines > 0 {
                        line += resetLines
                        col = m.suffix(from: index).utf8.count - 1
                    }

                    while
                        let comment = mutComments.first,
                        comment.loc <= loc {
                        line += comment.raw.countOccurrences(of: "\n")
                        col = comment.tail
                        loc += comment.length
                        mutComments.removeFirst()
                    }

                    adjustForComments()

                    break
                }
            }

            if !matched {
                let endIndex = content.index(after: content.startIndex)
                let contentRange = content.startIndex..<endIndex
                let contentNSRange = NSRange(contentRange, in: content)
                let str = String(content[contentRange])
                let inputNSRange = NSRange(location: contentNSRange.location + loc, length: contentNSRange.length)
                guard let inputRange = Range(inputNSRange, in: input) else { fatalError("invalid range") }

                tokens.append(Token(type: .Other(str), range: inputRange, line: line, col: col, loc: loc, raw: str))

                content = String(content[endIndex...])

                col += contentNSRange.length
                loc += contentNSRange.length
            }

            adjustForComments()
        }
        return (tokens: tokens, comments: comments)
    }
}
