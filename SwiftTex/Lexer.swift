//
//  Lexer.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

public enum Token {
    case Define
    case Identifier(String)
    case Number(Float)
    case ParensOpen
    case ParensClose
    case Comma
    case Other(String)
}

typealias TokenGenerator = (String) -> Token?
let tokenList: [(String, TokenGenerator)] = [
    ("[ \t\n]", { _ in nil }),
    ("[a-zA-Z][a-zA-Z0-9]*", { $0 == "def" ? .Define : .Identifier($0) }),
    ("[0-9.]+", { (r: String) in .Number((r as NSString).floatValue) }),
    ("\\(", { _ in .ParensOpen }),
    ("\\)", { _ in .ParensClose }),
    (",", { _ in .Comma }),
]

public class Lexer {
    let input: String
    init(input: String) {
        self.input = input
    }
    public func tokenize() -> [Token] {
        var tokens = [Token]()
        var content = input

        while content.lengthOfBytes(using: .utf8) > 0 {
            var matched = false

            for (pattern, generator) in tokenList {
                if let m = content.match(regex: pattern) {
                    if let t = generator(m) {
                        tokens.append(t)
                    }
                    let endIndex = content.index(content.startIndex, offsetBy: m.lengthOfBytes(using: .utf8))

                    content = String(content[endIndex...])
                    matched = true
                    break
                }
            }

            if !matched {
                let index = content.index(after: content.startIndex)
                tokens.append(.Other(String(content[..<index])))
                content = String(content[index...])
            }
        }
        return tokens
    }
}
