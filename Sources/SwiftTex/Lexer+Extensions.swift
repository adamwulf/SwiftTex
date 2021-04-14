//
//  Lexer+Extensions.swift
//  SwiftTex
//
//  Created by Adam Wulf on 12/6/20.
//

import Foundation

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
        if case Operator(let a) = lhs, case Operator(let b) = rhs {
            return a.rawValue == b.rawValue
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

extension Token.Symbol {
    var precedence: Int {
        let operatorPrecedence: [String: Int] = [
            "=": 10,
            "+": 20,
            "-": 20,
            "*": 40,
            " ": 40,
            "/": 40,
            "^": 60
        ]
        return operatorPrecedence[rawValue]!
    }
}

extension Token.Symbol: Equatable {
    static public func != (lhs: Token.Symbol, rhs: Token.Symbol) -> Bool {
        return !(lhs == rhs)
    }

    static public func == (lhs: Token.Symbol, rhs: Token.Symbol) -> Bool {
        if case plus = lhs, case plus = rhs {
            return true
        }
        if case minus = lhs, case minus = rhs {
            return true
        }
        if case mult = lhs, case mult = rhs {
            return true
        }
        if case div = lhs, case div = rhs {
            return true
        }
        if case exp = lhs, case exp = rhs {
            return true
        }
        if case equal = lhs, case equal = rhs {
            return true
        }
        return false
    }
}
