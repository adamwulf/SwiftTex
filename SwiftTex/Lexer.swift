//
//  Lexer.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

public struct Token {
    public enum Case {
        case Tex(String)
        case Identifier(String)
        case Number(Float)
        case ParensOpen
        case ParensClose
        case BraceOpen
        case BraceClose
        case Subscript
        case Comma
        case Other(String)
        case EOF
        case EOL
    }

    let type: Case
    let line: Int
    let col: Int
    let raw: String
}

extension Token.Case: Equatable {
    static public func != (lhs: Token.Case, rhs: Token.Case) -> Bool {
        return !(lhs == rhs)
    }

    static public func == (lhs: Token.Case, rhs: Token.Case) -> Bool {
        if case Tex(let a) = lhs, case Tex(let b) = rhs {
            return a == b
        }
        if case Identifier(let a) = lhs, case Identifier(let b) = rhs {
            return a == b
        }
        if case Number(let a) = lhs, case Number(let b) = rhs {
            return a == b
        }
        if case Other(let a) = lhs, case Other(let b) = rhs {
            return a == b
        }
        if case ParensOpen = lhs, case ParensOpen = rhs {
            return true
        }
        if case ParensClose = lhs, case ParensClose = rhs {
            return true
        }
        if case BraceOpen = lhs, case BraceOpen = rhs {
            return true
        }
        if case BraceClose = lhs, case BraceClose = rhs {
            return true
        }
        if case Subscript = lhs, case Subscript = rhs {
            return true
        }
        if case Comma = lhs, case Comma = rhs {
            return true
        }
        if case EOF = lhs, case EOF = rhs {
            return true
        }
        if case EOL = lhs, case EOL = rhs {
            return true
        }
        return false
    }
}

typealias TokenGenerator = (String, Int, Int) -> Token?
let tokenList: [(String, TokenGenerator)] = [
    ("[ \t]", { _, _, _ in nil }),
    ("[\n]", { s, l, c in Token(type: .EOL, line: l, col: c, raw: s) }),
    ("\\\\[a-zA-Z]+", { s, l, c in Token(type: .Tex(s), line: l, col: c, raw: s) }),
    ("[a-zA-Z]+", { s, l, c in Token(type: .Identifier(s), line: l, col: c, raw: s) }),
    ("[0-9.]+", { s, l, c in Token(type: .Number((s as NSString).floatValue), line: l, col: c, raw: s) }),
    ("\\(", { s, l, c in Token(type: .ParensOpen, line: l, col: c, raw: s) }),
    ("\\)", { s, l, c in Token(type: .ParensClose, line: l, col: c, raw: s) }),
    ("\\{", { s, l, c in Token(type: .BraceOpen, line: l, col: c, raw: s) }),
    ("\\}", { s, l, c in Token(type: .BraceClose, line: l, col: c, raw: s) }),
    ("_", { s, l, c in Token(type: .Subscript, line: l, col: c, raw: s) }),
    (",", { s, l, c in Token(type: .Comma, line: l, col: c, raw: s) }),
]

public class Lexer {
    let input: String
    init(input: String) {
        self.input = input
    }
    public func tokenize() -> [Token] {
        var tokens: [Token] = []
        var content = input
        var line = 0
        var col = 0

        while content.lengthOfBytes(using: .utf8) > 0 {
            var matched = false

            for (pattern, generator) in tokenList {
                if let m = content.match(regex: pattern) {
                    if let t = generator(m, line, col) {
                        tokens.append(t)

                        if case .EOL = t.type {
                            line += 1
                            col = 0
                        }
                    }
                    let endIndex = content.index(content.startIndex, offsetBy: m.lengthOfBytes(using: .utf8))

                    col += m.lengthOfBytes(using: .utf8)

                    content = String(content[endIndex...])
                    matched = true
                    break
                }
            }

            if !matched {
                let index = content.index(after: content.startIndex)
                let str = String(content[..<index])
                tokens.append(Token(type: .Other(str), line: line, col: col, raw: str))
                content = String(content[index...])

                col += 1
            }
        }
        return tokens
    }
}
