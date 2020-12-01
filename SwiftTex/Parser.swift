//
//  Parser.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

enum Errors: Error {
    case UnexpectedToken(token: Token)
    case UndefinedOperator(String, token: Token)

    case ExpectedCharacter(Character, token: Token)
    case ExpectedExpression(token: Token)
    case ExpectedArgumentList(token: Token)
    case ExpectedFunctionName(token: Token)
    case EOF
}

class Parser {
    let tokens: [Token]
    var index = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    func peekCurrentToken() -> Token? {
        guard index < tokens.count else { return nil }
        return tokens[index]
    }

    @discardableResult
    func popCurrentToken() throws -> Token {
        guard index < tokens.count else { throw Errors.EOF }
        let token = tokens[index]
        index += 1
        return token
    }

    func parseNumber() throws -> ExprNode {
        let token = try popCurrentToken()
        guard case let Token.Case.Number(value) = token.type
        else {
            throw Errors.UnexpectedToken(token: token)
        }
        return NumberNode(value: value)
    }

    func parseExpression() throws -> ExprNode {
        let node = try parsePrimary()
        return try parseBinaryOp(node: node)
    }

    func parseParens() throws -> ExprNode {
        var token = try popCurrentToken()
        guard case Token.Case.ParensOpen = token.type else {
            throw Errors.ExpectedCharacter("(", token: token)
        }

        let exp = try parseExpression()

        token = try popCurrentToken()
        guard case Token.Case.ParensClose = token.type else {
            throw Errors.ExpectedCharacter(")", token: token)
        }

        return exp
    }

    func parseBraceList() throws -> [BracedNode] {
        var arguments: [BracedNode] = []

        while
            let token = peekCurrentToken(),
            case Token.Case.BraceOpen = token.type {
            arguments.append(try parseBraceExpr())
        }

        return arguments
    }

    func parseBraceExpr() throws -> BracedNode {
        guard let token = peekCurrentToken() else {
            throw Errors.EOF
        }
        guard case Token.Case.BraceOpen = token.type else {
            throw Errors.ExpectedCharacter("{", token: token)
        }

        var expressions: [ExprNode] = []
        while
            let token = peekCurrentToken(),
            case Token.Case.BraceOpen = token.type {
            try popCurrentToken()

            while
                let token = peekCurrentToken(),
                Token.Case.BraceClose != token.type {
                let argument = try parseExpression()
                expressions.append(argument)
            }

            if Token.Case.BraceClose == peekCurrentToken()?.type {
                break
            }
        }

        // pop the }
        try popCurrentToken()

        return BracedNode(expressions: expressions)
    }

    func parseTex() throws -> ExprNode {
        let token = try popCurrentToken()
        guard case let Token.Case.Tex(name) = token.type else {
            throw Errors.UnexpectedToken(token: token)
        }

        let maybeToken = peekCurrentToken()
        guard Token.Case.BraceOpen == maybeToken?.type else {
            return TexNode(name: name, arguments: [])
        }

        let arguments = try parseBraceList()

        return TexNode(name: name, arguments: arguments)

    }

    func parseIdentifier() throws -> ExprNode {
        let token = try popCurrentToken()
        guard case let Token.Case.Identifier(name) = token.type else {
            throw Errors.UnexpectedToken(token: token)
        }

        var subscripts: [ExprNode] = []

        while
            let sub = peekCurrentToken(),
            Token.Case.Subscript == sub.type {
            try popCurrentToken()

            let maybeToken = peekCurrentToken()
            if Token.Case.BraceOpen == maybeToken?.type {
                subscripts.append(try parseBraceExpr())
            } else {
                subscripts.append(try parseExpression())
            }
        }

        return VariableNode(name: name, subscripts: subscripts)
    }

    func parsePrimary() throws -> ExprNode {
        guard let token = peekCurrentToken() else { throw Errors.EOF }
        switch token.type {
        case .Tex:
            return try parseTex()
        case .Identifier:
            return try parseIdentifier()
        case .Number:
            return try parseNumber()
        case .ParensOpen:
            return try parseParens()
        default:
            throw Errors.ExpectedExpression(token: token)
        }
    }

    let operatorPrecedence: [String: Int] = [
        "+": 20,
        "-": 20,
        "*": 40,
        "/": 40,
        "=": 10
    ]

    func getCurrentTokenPrecedence() throws -> Int {
        guard index < tokens.count else {
            return -1
        }

        guard let token = peekCurrentToken(),
              case let Token.Case.Other(op) = token.type
        else {
            return -1
        }

        guard let precedence = operatorPrecedence[op] else {
            throw Errors.UndefinedOperator(op, token: token)
        }

        return precedence
    }

    func parseBinaryOp(node: ExprNode, exprPrecedence: Int = 0) throws -> ExprNode {
        var lhs = node
        while true {
            let tokenPrecedence = try getCurrentTokenPrecedence()
            if tokenPrecedence < exprPrecedence {
                return lhs
            }

            let token = try popCurrentToken()
            guard case let Token.Case.Other(op) = token.type else {
                throw Errors.UnexpectedToken(token: token)
            }

            var rhs = try parsePrimary()
            let nextPrecedence = try getCurrentTokenPrecedence()

            if tokenPrecedence < nextPrecedence {
                rhs = try parseBinaryOp(node: rhs, exprPrecedence: tokenPrecedence + 1)
            }
            lhs = BinaryOpNode(op: op, lhs: lhs, rhs: rhs)
        }
    }

    func parsePrototype() throws -> PrototypeNode {
        var token = try popCurrentToken()
        guard case let Token.Case.Identifier(name) = token.type else {
            throw Errors.ExpectedFunctionName(token: token)
        }

        token = try popCurrentToken()
        guard case Token.Case.ParensOpen = token.type else {
            throw Errors.ExpectedCharacter("(", token: token)
        }

        var argumentNames = [String]()
        while
            let token = peekCurrentToken(),
            case let Token.Case.Identifier(name) = token.type {
            try popCurrentToken()
            argumentNames.append(name)

            if
                let token = peekCurrentToken(),
                case Token.Case.ParensClose = token.type {
                break
            }

            let token = try popCurrentToken()
            guard case Token.Case.Comma = token.type else {
                throw Errors.ExpectedArgumentList(token: token)
            }
        }

        // remove ")"
        try popCurrentToken()

        return PrototypeNode(name: name, argumentNames: argumentNames)
    }

    func parseDefinition() throws -> FunctionNode {
        try popCurrentToken()
        let prototype = try parsePrototype()
        let body = try parseExpression()
        return FunctionNode(prototype: prototype, body: body)
    }

    func parseTopLevelExpr() throws -> FunctionNode {
        let prototype = PrototypeNode(name: "", argumentNames: [])
        let body = try parseExpression()
        return FunctionNode(prototype: prototype, body: body)
    }

    func parse() throws -> [Any] {
        index = 0

        var nodes = [Any]()
        while index < tokens.count {
            let expr = try parseExpression()
            nodes.append(expr)
        }

        return nodes
    }
}
