//
//  Lexer.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

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

        var rawValue: String {
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

    let type: Case
    let line: Int
    let col: Int
    let raw: String
}

typealias TokenGenerator = (String, Int, Int) -> Token?
let tokenList: [(String, TokenGenerator)] = [
    ("\n\n", { s, l, c in Token(type: .EOL, line: l, col: c, raw: s) }),
    ("[ \t\n]", { _, _, _ in nil }),
//    ("[\n][\\s]+", { _, _, _ in nil }),
//    ("[\n]", { s, l, c in Token(type: .EOL, line: l, col: c, raw: s) }),
    ("\\\\[a-zA-Z]+", { s, l, c in Token(type: .Tex(s), line: l, col: c, raw: s) }),
    ("[a-zA-Z]+", { s, l, c in Token(type: .Identifier(s), line: l, col: c, raw: s) }),
    ("[\\-]?[0-9]+\\.?[0-9]*", { s, l, c in Token(type: .Number(s), line: l, col: c, raw: s) }),
    ("\\(", { s, l, c in Token(type: .ParensOpen, line: l, col: c, raw: s) }),
    ("\\)", { s, l, c in Token(type: .ParensClose, line: l, col: c, raw: s) }),
    ("\\{", { s, l, c in Token(type: .BraceOpen, line: l, col: c, raw: s) }),
    ("\\}", { s, l, c in Token(type: .BraceClose, line: l, col: c, raw: s) }),
    ("_", { s, l, c in Token(type: .Subscript, line: l, col: c, raw: s) }),
    (",", { s, l, c in Token(type: .Comma, line: l, col: c, raw: s) }),
    ("[\\+\\-\\*/\\^=]", { s, l, c in Token(type: .Operator(Token.Symbol.from(s)!), line: l, col: c, raw: s) })
]

public class Lexer {
    let input: String
    public init(input: String) {
        self.input = input
    }
    public func tokenize() -> [Token] {
        var tokens: [Token] = []
        var content = input
        var line = 1
        var col = 0

        while let (_, range) = content.match(regex: "%[^\n]*[ \t\n]*", mustStart: false) {
            content = (content as NSString).replacingCharacters(in: range, with: "")
        }

        while content.lengthOfBytes(using: .utf8) > 0 {
            var matched = false

            for (pattern, generator) in tokenList {
                if let (m, _) = content.match(regex: pattern, mustStart: true) {
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
