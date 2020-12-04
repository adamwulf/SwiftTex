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
    case MismatchedName(token: Token)
    case InvalidArgumentCount(token: Token)
    case InvalidFunctionBody(token: Token)
    case InvalidSubscript(token: Token)
    case EOF
}

class Parser {
    let tokens: [Token]
    var index = 0
    var functions: [PrototypeNode] = []

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

    func popEOLs() throws {
        while Token.Case.EOL == peekCurrentToken()?.type {
            try popCurrentToken()
        }
    }

    func parseNumber() throws -> ExprNode {
        let token = try popCurrentToken()
        guard case let Token.Case.Number(value) = token.type
        else {
            throw Errors.UnexpectedToken(token: token)
        }
        return NumberNode(value: value, startToken: token)
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

    /// Parses a list of braced expressions `{a}{b}{c}`
    func parseBraceList() throws -> [BracedNode] {
        var arguments: [BracedNode] = []

        while
            let token = peekCurrentToken(),
            case Token.Case.BraceOpen = token.type {
            arguments.append(try parseBraceExpr())
            try popEOLs()
        }

        return arguments
    }

    /// Parses a list of braced expressions `{mumble}{jumble}{bumble}`
    func parseBraceTextList() throws -> [String] {
        var arguments: [String] = []

        while
            let token = peekCurrentToken(),
            case Token.Case.BraceOpen = token.type {
            try popCurrentToken()
            var text = ""
            while let next = peekCurrentToken(),
                  next.type != .BraceClose {
                text += next.raw
                try popCurrentToken()
            }

            let closed = try popCurrentToken()

            guard closed.type == Token.Case.BraceClose else { throw Errors.ExpectedCharacter("}", token: closed) }
            arguments.append(text)
        }

        return arguments
    }

    /// Parses a single `{a}`
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
                try popEOLs()
                expressions.append(argument)
            }

            if Token.Case.BraceClose == peekCurrentToken()?.type {
                break
            }
        }

        // pop the }
        try popCurrentToken()

        return BracedNode(expressions: expressions, startToken: token)
    }

    func parseTex() throws -> ExprNode {
        let token = try popCurrentToken()
        guard case let Token.Case.Tex(name) = token.type else {
            throw Errors.UnexpectedToken(token: token)
        }

        if name == "\\end" {
            let arguments = try parseBraceTextList()

            return TexListNode.TexListSuffix(name: name, arguments: arguments, startToken: token)
        } else if name == "\\begin" {
            let arguments = try parseBraceTextList()

            guard let beginName = arguments.first else { throw Errors.ExpectedArgumentList(token: token)}
            var expressions: [ExprNode] = []

            repeat {
                try popEOLs()
                expressions.append(try parseExpression())
            } while expressions.last as? TexListNode.TexListSuffix == nil

            guard
                let endNode = expressions.last as? TexListNode.TexListSuffix,
                let endName = endNode.arguments.first,
                endName == beginName
            else {
                throw Errors.MismatchedName(token: expressions.last!.startToken )
            }

            expressions.removeLast()

            return TexListNode(name: beginName, arguments: arguments, expressions: expressions, startToken: token)
        }

        try popEOLs()
        let maybeToken = peekCurrentToken()
        guard Token.Case.BraceOpen == maybeToken?.type else {
            return TexNode(name: name, arguments: [], startToken: token)
        }

        if name == "\\func" {
            // pop the {
            let brace = try popCurrentToken()
            try popEOLs()
            let prototype = try parsePrototype()
            try popEOLs()
            let closeBrace = try popCurrentToken()
            guard Token.Case.BraceClose == closeBrace.type else {
                throw Errors.UnexpectedToken(token: closeBrace)
            }

            functions.append(prototype)

            try popEOLs()
            let body = try parseBraceExpr()
            if
                let body = body.unwrap(),
                body as? BracedNode == nil {
                return FunctionNode(prototype: prototype, body: body, startToken: token)
            }

            throw Errors.InvalidFunctionBody(token: brace)
        }

        let arguments = try parseBraceList()

        if name == "\\frac" {
            guard
                arguments.count == 2,
                let numerator = arguments.first?.unwrap(),
                let denominator = arguments.last?.unwrap()
            else {
                throw Errors.InvalidArgumentCount(token: token)
            }

            return BinaryOpNode(op: "/", lhs: numerator, rhs: denominator, startToken: token)
        }

        return TexNode(name: name, arguments: arguments, startToken: token)
    }

    func parseIdentifier() throws -> VariableNode {
        let token = try popCurrentToken()
        guard case let Token.Case.Identifier(name) = token.type else {
            throw Errors.UnexpectedToken(token: token)
        }

        var subscripts: [ExprNode] = []

        while
            let sub = peekCurrentToken(),
            Token.Case.Subscript == sub.type {
            try popCurrentToken()

            guard let maybeToken = peekCurrentToken() else {
                throw Errors.EOF
            }
            if Token.Case.BraceOpen == maybeToken.type {
                let braced = try parseBraceExpr()
                guard let unwrapped = braced.unwrap() else {
                    throw Errors.ExpectedExpression(token: token)
                }
                subscripts.append(unwrapped)
            } else if case Token.Case.Identifier = maybeToken.type {
                subscripts.append(try parseIdentifier())
            } else if case Token.Case.Number = maybeToken.type {
                subscripts.append(try parseNumber())
            } else {
                throw Errors.InvalidSubscript(token: maybeToken)
            }
        }

        return VariableNode(name: name, subscripts: subscripts, startToken: token)
    }

    let operatorPrecedence: [String: Int] = [
        "=": 10,
        "+": 20,
        "-": 20,
        "*": 40,
        "/": 40,
        "^": 60,
    ]

    func getCurrentTokenPrecedence() throws -> Int {
        guard index < tokens.count else {
            return -1
        }

        guard let token = peekCurrentToken()
        else {
            return -1
        }

        if case let Token.Case.Other(op) = token.type {
            guard let precedence = operatorPrecedence[op] else {
                throw Errors.UndefinedOperator(op, token: token)
            }
            return precedence
        }

        switch token.type {
        case Token.Case.Identifier:
            fallthrough
        case Token.Case.Number:
            fallthrough
        case Token.Case.ParensOpen:
            let op = "*"
            guard let precedence = operatorPrecedence[op] else {
                throw Errors.UndefinedOperator(op, token: token)
            }
            return precedence
        default:
            return -1
        }
    }

    func parseBinaryOp(node: ExprNode, exprPrecedence: Int = 0) throws -> ExprNode {
        var lhs = node
        while true {
            try popEOLs()
            let tokenPrecedence = try getCurrentTokenPrecedence()
            if tokenPrecedence < exprPrecedence {
                return lhs
            }

            guard var opToken = peekCurrentToken() else { throw Errors.EOF }
            var op = "*"

            if let opToken = peekCurrentToken(),
               case let Token.Case.Other(trueOp) = opToken.type {
                try popCurrentToken()
                op = trueOp
            } else {
                // inferred multiplication
                opToken = Token(type: .Other("*"), line: opToken.line, col: opToken.col, raw: "")
            }

            try popEOLs()
            var rhs = try parsePrimary()

            try popEOLs()
            let nextPrecedence = try getCurrentTokenPrecedence()

            if tokenPrecedence < nextPrecedence {
                rhs = try parseBinaryOp(node: rhs, exprPrecedence: tokenPrecedence + 1)
            }
            lhs = BinaryOpNode(op: op, lhs: lhs, rhs: rhs, startToken: opToken)
        }
    }

    func parsePrototype() throws -> PrototypeNode {
        guard let maybeToken = peekCurrentToken() else { throw Errors.EOF }
        guard case Token.Case.Identifier = maybeToken.type else {
            throw Errors.ExpectedFunctionName(token: maybeToken)
        }

        let name = try parseIdentifier()

        let token = try popCurrentToken()
        guard case Token.Case.ParensOpen = token.type else {
            throw Errors.ExpectedCharacter("(", token: token)
        }

        var argumentNames: [VariableNode] = []
        while
            let token = peekCurrentToken(),
            case Token.Case.Identifier = token.type {
            argumentNames.append(try parseIdentifier())

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

        return PrototypeNode(name: name, argumentNames: argumentNames, startToken: token)
    }

    func parseTopLevelExpr() throws -> FunctionNode {
        let body = try parseExpression()
        let token = body.startToken
        let prototype = PrototypeNode(name: VariableNode(name: "", subscripts: [], startToken: token), argumentNames: [], startToken: token)
        return FunctionNode(prototype: prototype, body: body, startToken: token)
    }

    func parseCall(function: VariableNode) throws -> ExprNode {
        let token = try popCurrentToken()
        guard case Token.Case.ParensOpen = token.type else {
            throw Errors.ExpectedCharacter("(", token: token)
        }

        var parameters: [ExprNode] = []
        while true {
            parameters.append(try parseExpression())

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

        return CallNode(callee: function, arguments: parameters, startToken: token)
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

    func parseExpression() throws -> ExprNode {
        let node = try parsePrimary()

        if
            let function = node as? VariableNode,
            functions.contains(where: { $0.name.name == function.name }) {
            return try parseCall(function: function)
        } else if node as? FunctionNode != nil {
            return node
        }

        return try parseBinaryOp(node: node)
    }

    func parse() throws -> [Any] {
        index = 0

        var nodes: [ExprNode] = []
        var line: [ExprNode] = []
        while index < tokens.count {
            // ignore line endings between statements
            while Token.Case.EOL == peekCurrentToken()?.type {
                nodes.append(contentsOf: line)
                line.removeAll()
                try popCurrentToken()
            }

            if index >= tokens.count {
                // we might have only EOLs left
                break
            }

            let expr = try parseExpression()
            line.append(expr)
        }

        nodes.append(contentsOf: line)

        return nodes
    }
}
