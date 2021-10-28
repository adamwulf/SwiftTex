//
//  Parser.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

public enum ParseError: Error {
    case UnexpectedToken(token: Token)
    case UndefinedOperator(String, token: Token)
    case ExpectedCharacter(Character, token: Token)
    case ExpectedExpression(token: Token)
    case ExpectedArgumentList(token: Token)
    case ExpectedFunctionName(token: Token)
    case MismatchedName(token: Token)
    case UnendingList(token: Token)
    case InvalidArgumentCount(token: Token)
    case InvalidFunctionBody(token: Token)
    case InvalidSubscript(token: Token)
    case InvalidLetVariable(token: Token)
    case InvalidLetValue(token: Token)
    case EOF

    public var token: Token? {
        switch self {
        case .UnexpectedToken(let token): return token
        case .UndefinedOperator(_, let token): return token
        case .ExpectedCharacter(_, let token): return token
        case .ExpectedExpression(let token): return token
        case .ExpectedArgumentList(let token): return token
        case .ExpectedFunctionName(let token): return token
        case .MismatchedName(let token): return token
        case .UnendingList(let token): return token
        case .InvalidArgumentCount(let token): return token
        case .InvalidFunctionBody(let token): return token
        case .InvalidSubscript(let token): return token
        case .InvalidLetVariable(token: let token): return token
        case .InvalidLetValue(token: let token): return token
        case .EOF: return nil
        }
    }

}

public class Parser {

    public typealias Result = (expressions: [ExprNode], errors: [ParseError])

    let tokens: [Token]
    var index = 0
    var functions: [PrototypeNode] = []

    // MARK: - Settings

    private var settingsStack: [Settings]
    private var settings: Settings {
        settingsStack.last!
    }

    private func pushSettings(_ settings: Settings) {
        settingsStack.append(settings)
    }

    private func popSettings() {
        settingsStack.removeLast()
    }

    private func useSettings(_ settings: Settings, during block: (() throws -> Void)) throws {
        pushSettings(settings)
        try block()
        popSettings()
    }

    private struct Settings {
        let allowImplicitMult: Bool
    }

    // MARK: - Init

    public init(tokens: [Token]) {
        self.settingsStack = [Settings(allowImplicitMult: true)]
        self.tokens = tokens
    }

    // MARK: - Tokens

    func peekCurrentToken() -> Token? {
        guard index < tokens.count else { return nil }
        return tokens[index]
    }

    @discardableResult
    func popCurrentToken() throws -> Token {
        guard index < tokens.count else { throw ParseError.EOF }
        let token = tokens[index]
        index += 1
        return token
    }

    // MARK: - Parse Methods

    func parseNumber() throws -> ExprNode {
        let token = try popCurrentToken()
        guard case let Token.Case.Number(value) = token.type
        else {
            throw ParseError.UnexpectedToken(token: token)
        }
        return NumberNode(string: value, startToken: token)
    }

    func parseParens() throws -> ExprNode {
        var token = try popCurrentToken()
        guard case Token.Case.ParensOpen = token.type else {
            throw ParseError.ExpectedCharacter("(", token: token)
        }

        let exp = try parseExpression()

        token = try popCurrentToken()
        guard case Token.Case.ParensClose = token.type else {
            throw ParseError.ExpectedCharacter(")", token: token)
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

            guard closed.type == Token.Case.BraceClose else { throw ParseError.ExpectedCharacter("}", token: closed) }
            arguments.append(text)
        }

        return arguments
    }

    /// Parses a single `{a}`
    func parseBraceExpr() throws -> BracedNode {
        guard let token = peekCurrentToken() else {
            throw ParseError.EOF
        }
        guard case Token.Case.BraceOpen = token.type else {
            throw ParseError.ExpectedCharacter("{", token: token)
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

        return BracedNode(children: expressions, startToken: token)
    }

    func parseTextList() throws -> TexListNode {
        guard let beginToken = peekCurrentToken() else { throw ParseError.EOF }
        guard case let Token.Case.Tex(name) = beginToken.type,
              name == "\\begin"
              else {
            throw ParseError.UnexpectedToken(token: beginToken)
        }

        try popCurrentToken()
        let arguments = try parseBraceTextList()

        guard let beginName = arguments.first else { throw ParseError.ExpectedArgumentList(token: beginToken)}
        var expressions: [ExprNode] = []

        while true {
            while Token.Case.EOL == peekCurrentToken()?.type {
                try popCurrentToken()
            }
            if let nextToken = peekCurrentToken(),
               case Token.Case.Tex(let texName) = nextToken.type,
               texName == "\\end" {
                try popCurrentToken() // pop the \\end
                let endArguments = try parseBraceTextList()
                let endName = endArguments.first

                if endName == beginName {
                    break
                } else {
                    throw ParseError.MismatchedName(token: nextToken )
                }
            }

            guard let expression = try parseTopLevelExpression() else {
                throw ParseError.UnendingList(token: beginToken)
            }

            expressions.append(expression)
        }

        return TexListNode(name: beginName, arguments: arguments, children: expressions, startToken: beginToken)
    }

    func parseFunc() throws -> FunctionNode {
        guard let token = peekCurrentToken() else { throw ParseError.EOF }
        guard case let Token.Case.Tex(name) = token.type,
              name == "\\func"
              else {
            throw ParseError.UnexpectedToken(token: token)
        }

        try popCurrentToken()

        // pop the {
        let openBrace = try popCurrentToken()
        guard Token.Case.BraceOpen == openBrace.type else {
            throw ParseError.UnexpectedToken(token: openBrace)
        }

        let prototype = try parsePrototype()

        let closeBrace = try popCurrentToken()
        guard Token.Case.BraceClose == closeBrace.type else {
            throw ParseError.UnexpectedToken(token: closeBrace)
        }

        functions.append(prototype)

        let body = try parseBraceExpr()
        if
            let body = body.unwrap(),
            body as? BracedNode == nil {
            return FunctionNode(prototype: prototype, body: body, closed: [:], startToken: token)
        }

        throw ParseError.InvalidFunctionBody(token: openBrace)
    }

    func parseFrac() throws -> BinaryOpNode {
        guard let token = peekCurrentToken() else { throw ParseError.EOF }
        guard case let Token.Case.Tex(name) = token.type,
              name == "\\frac"
              else {
            throw ParseError.UnexpectedToken(token: token)
        }

        try popCurrentToken()

        let arguments = try parseBraceList()

        guard
            arguments.count == 2,
            let numerator = arguments.first?.unwrap(),
            let denominator = arguments.last?.unwrap()
        else {
            throw ParseError.InvalidArgumentCount(token: token)
        }

        return BinaryOpNode(op: .div, lhs: numerator, rhs: denominator, startToken: token)
    }

    func parseLet() throws -> LetNode {
        guard let token = peekCurrentToken() else { throw ParseError.EOF }
        guard case let Token.Case.Tex(name) = token.type,
              name == "\\let"
              else {
            throw ParseError.UnexpectedToken(token: token)
        }

        try popCurrentToken()

        let arguments = try parseBraceList()

        guard
            arguments.count == 2,
            arguments.first?.children.count == 1,
            let numerator = arguments.first?.unwrap()
        else {
            throw ParseError.InvalidArgumentCount(token: token)
        }

        guard let variable = numerator as? VariableNode else { throw ParseError.InvalidLetVariable(token: numerator.startToken) }
        guard
            arguments.last?.children.count == 1,
            let value = arguments.last?.unwrap()
        else {
            throw ParseError.InvalidLetValue(token: variable.startToken)
        }

        return LetNode(variable: variable, value: value, startToken: token)
    }

    func parseTex() throws -> ExprNode {
        guard let token = peekCurrentToken() else { throw ParseError.EOF }
        guard case let Token.Case.Tex(name) = token.type else { throw ParseError.UnexpectedToken(token: token) }

        switch name {
        case "\\begin":
            return try parseTextList()
        case "\\func":
            return try parseFunc()
        case "\\frac":
            return try parseFrac()
        case "\\let":
            return try parseLet()
        default:
            let token = try popCurrentToken()
            let arguments = try parseBraceList()
            return TexNode(name: name, arguments: arguments, startToken: token)
        }
    }

    func parseIdentifier() throws -> VariableNode {
        let token = try popCurrentToken()
        guard case let Token.Case.Identifier(name) = token.type else {
            throw ParseError.UnexpectedToken(token: token)
        }

        var subscripts: [ExprNode] = []

        while
            let sub = peekCurrentToken(),
            Token.Case.Subscript == sub.type {
            try popCurrentToken()

            guard let maybeToken = peekCurrentToken() else {
                throw ParseError.EOF
            }
            if Token.Case.BraceOpen == maybeToken.type {
                try useSettings(Settings(allowImplicitMult: false)) {
                    let braced = try parseBraceExpr()
                    subscripts = braced.children
                }
            } else if case Token.Case.Identifier = maybeToken.type {
                subscripts.append(try parseIdentifier())
            } else if case Token.Case.Number = maybeToken.type {
                subscripts.append(try parseNumber())
            } else {
                throw ParseError.InvalidSubscript(token: maybeToken)
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
        "^": 60
    ]

    func getCurrentTokenPrecedence() throws -> Int {
        guard index < tokens.count else {
            return -1
        }

        guard let token = peekCurrentToken()
        else {
            return -1
        }

        if case let Token.Case.Operator(op) = token.type {
            return op.precedence
        }

        guard settings.allowImplicitMult else { return -1 }

        switch token.type {
        case Token.Case.Identifier:
            fallthrough
        case Token.Case.Number:
            fallthrough
        case Token.Case.ParensOpen:
            return Token.Symbol.mult(implicit: true).precedence
        default:
            return -1
        }
    }

    func parseUnary() throws -> UnaryOpNode {
        let token = try popCurrentToken()
        guard
            case let Token.Case.Operator(op) = token.type,
            op.isUnary
        else {
            throw ParseError.UnexpectedToken(token: token)
        }

        let exp = try parseExpression()

        return UnaryOpNode(op: op, expression: exp, startToken: token)
    }

    func parseBinaryOp(node: ExprNode, exprPrecedence: Int = 0) throws -> ExprNode {
        var lhs = node
        while true {
            let tokenPrecedence = try getCurrentTokenPrecedence()
            if tokenPrecedence < exprPrecedence {
                return lhs
            }

            guard var opToken = peekCurrentToken() else { throw ParseError.EOF }
            var op = Token.Symbol.mult(implicit: true)

            if let opToken = peekCurrentToken(),
               case let Token.Case.Operator(trueOp) = opToken.type {
                if op.isBinary {
                    try popCurrentToken()
                    op = trueOp
                } else {
                    throw ParseError.UnexpectedToken(token: opToken)
                }
            } else {
                // inferred multiplication
                opToken = Token(type: .Operator(op),
                                range: Range(uncheckedBounds: (lower: opToken.range.lowerBound, upper: opToken.range.lowerBound)),
                                line: opToken.line,
                                col: opToken.col,
                                loc: opToken.loc,
                                raw: op.rawValue)
            }

            var rhs = try parsePrimary()

            let nextPrecedence = try getCurrentTokenPrecedence()

            if tokenPrecedence < nextPrecedence {
                rhs = try parseBinaryOp(node: rhs, exprPrecedence: tokenPrecedence + 1)
            }
            lhs = BinaryOpNode(op: op, lhs: lhs, rhs: rhs, startToken: opToken)
        }
    }

    func parsePrototype() throws -> PrototypeNode {
        guard let maybeToken = peekCurrentToken() else { throw ParseError.EOF }
        guard case Token.Case.Identifier = maybeToken.type else {
            throw ParseError.ExpectedFunctionName(token: maybeToken)
        }

        let name = try parseIdentifier()

        let token = try popCurrentToken()
        guard case Token.Case.ParensOpen = token.type else {
            throw ParseError.ExpectedCharacter("(", token: token)
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
                throw ParseError.ExpectedArgumentList(token: token)
            }
        }

        // remove ")"
        try popCurrentToken()

        return PrototypeNode(name: name, argumentNames: argumentNames, startToken: token)
    }

    func parseFunction() throws -> FunctionNode {
        let body = try parseExpression()
        let token = body.startToken
        let prototype = PrototypeNode(name: VariableNode(name: "", subscripts: [], startToken: token), argumentNames: [], startToken: token)
        return FunctionNode(prototype: prototype, body: body, closed: [:], startToken: token)
    }

    func parseCall(function: VariableNode) throws -> ExprNode {
        let token = try popCurrentToken()
        guard case Token.Case.ParensOpen = token.type else {
            throw ParseError.ExpectedCharacter("(", token: token)
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
                throw ParseError.ExpectedArgumentList(token: token)
            }
        }

        // remove ")"
        try popCurrentToken()

        return CallNode(callee: function, arguments: parameters, startToken: token)
    }

    func parsePrimary() throws -> ExprNode {
        guard let token = peekCurrentToken() else { throw ParseError.EOF }
        switch token.type {
        case .Tex:
            return try parseTex()
        case .Operator:
            return try parseUnary()
        case .Identifier:
            return try parseIdentifier()
        case .Number:
            return try parseNumber()
        case .ParensOpen:
            return try parseParens()
        default:
            throw ParseError.ExpectedExpression(token: token)
        }
    }

    func parseExpression() throws -> ExprNode {
        var node = try parsePrimary()

        guard node as? FunctionNode == nil else { return node }

        if
            let function = node as? VariableNode,
            functions.contains(where: { $0.name.name == function.name }) {
            node = try parseCall(function: function)
        }

        return try parseBinaryOp(node: node)
    }

    func parseTopLevelExpression() throws -> ExprNode? {
        // ignore line endings between statements
        while Token.Case.EOL == peekCurrentToken()?.type {
            try popCurrentToken()
        }

        guard peekCurrentToken() != nil else { return nil }

        return try parseExpression()
    }

    // MARK: - Public API

    public func parse() throws -> Result {
        index = 0
        var nodes: [ExprNode] = []
        var errors: [ParseError] = []
        while index < tokens.count {
            do {
                if let expression = try parseTopLevelExpression() {
                    nodes.append(expression)
                }
            } catch {
                guard let parseError = error as? ParseError else { throw error }

                errors.append(parseError)

                while let token = peekCurrentToken() {
                    if case .Tex(_) = token.type {
                        // we found a likely starting point for parsing, try to start again here
                        break
                    } else if case .EOL = token.type {
                        // we found a likely starting point for parsing, try to start again here
                        break
                    } else {
                        try popCurrentToken()
                    }
                }
            }
        }

        return (expressions: nodes, errors: errors)
    }
}
