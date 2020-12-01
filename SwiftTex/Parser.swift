//
//  Parser.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

enum Errors: Error {
    case UnexpectedToken
    case UndefinedOperator(String)

    case ExpectedCharacter(Character)
    case ExpectedExpression
    case ExpectedArgumentList
    case ExpectedFunctionName
}

class Parser {
    let tokens: [Token]
    var index = 0

    init(tokens: [Token]) {
        self.tokens = tokens
    }

    func peekCurrentToken() -> Token {
        guard index < tokens.count else { return .EOF }
        return tokens[index]
    }

    @discardableResult
    func popCurrentToken() -> Token {
        guard index < tokens.count else { return .EOF }
        let token = tokens[index]
        index += 1
        return token
    }

    func parseNumber() throws -> ExprNode {
        guard case let Token.Number(value) = popCurrentToken() else {
            throw Errors.UnexpectedToken
        }
        return NumberNode(value: value)
    }

    func parseExpression() throws -> ExprNode {
        let node = try parsePrimary()
        return try parseBinaryOp(node: node)
    }

    func parseParens() throws -> ExprNode {
        guard case Token.ParensOpen = popCurrentToken() else {
            throw Errors.ExpectedCharacter("(")
        }

        let exp = try parseExpression()

        guard case Token.ParensClose = popCurrentToken() else {
            throw Errors.ExpectedCharacter(")")
        }

        return exp
    }

    func parseBraceList() throws -> [ExprNode] {
        var arguments = [ExprNode]()
        while case Token.BraceOpen = peekCurrentToken() {
            popCurrentToken()

            if case Token.BraceClose = peekCurrentToken() {
            } else {
                let argument = try parseExpression()
                arguments.append(argument)

                if case Token.BraceClose = peekCurrentToken() {
                    break
                }
            }
        }

        // pop the }
        popCurrentToken()

        return arguments
    }

    func parseTex() throws -> ExprNode {
        guard case let Token.Tex(name) = popCurrentToken() else {
            throw Errors.UnexpectedToken
        }

        guard case Token.BraceOpen = peekCurrentToken() else {
            return TexNode(name: name, arguments: [])
        }

        let arguments = try parseBraceList()

        return TexNode(name: name, arguments: arguments)

    }

    func parseIdentifier() throws -> ExprNode {
        guard case let Token.Identifier(name) = popCurrentToken() else {
            throw Errors.UnexpectedToken
        }

        guard case Token.Subscript = peekCurrentToken() else {
            return VariableNode(name: name, subscripts: [])
        }

        popCurrentToken()

        var subscripts = [ExprNode]()
        if case Token.BraceOpen = peekCurrentToken() {
            subscripts.append(contentsOf: try parseBraceList())
        } else {
            subscripts.append(try parseExpression())
        }

        return VariableNode(name: name, subscripts: subscripts)
    }

    func parsePrimary() throws -> ExprNode {
        switch peekCurrentToken() {
        case .Tex:
            return try parseTex()
        case .Identifier:
            return try parseIdentifier()
        case .Number:
            return try parseNumber()
        case .ParensOpen:
            return try parseParens()
        default:
            throw Errors.ExpectedExpression
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

        guard case let Token.Other(op) = peekCurrentToken() else {
            return -1
        }

        guard let precedence = operatorPrecedence[op] else {
            throw Errors.UndefinedOperator(op)
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

            guard case let Token.Other(op) = popCurrentToken() else {
                throw Errors.UnexpectedToken
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
        guard case let Token.Identifier(name) = popCurrentToken() else {
            throw Errors.ExpectedFunctionName
        }

        guard case Token.ParensOpen = popCurrentToken() else {
            throw Errors.ExpectedCharacter("(")
        }

        var argumentNames = [String]()
        while case let Token.Identifier(name) = peekCurrentToken() {
            popCurrentToken()
            argumentNames.append(name)

            if case Token.ParensClose = peekCurrentToken() {
                break
            }

            guard case Token.Comma = popCurrentToken() else {
                throw Errors.ExpectedArgumentList
            }
        }

        // remove ")"
        popCurrentToken()

        return PrototypeNode(name: name, argumentNames: argumentNames)
    }

    func parseDefinition() throws -> FunctionNode {
        popCurrentToken()
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
