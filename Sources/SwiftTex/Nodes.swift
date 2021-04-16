//
//  Nodes.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

public protocol ExprNode: Visitable, CustomStringConvertible {
    var startToken: Token { get }
}

public protocol Visitor {
    associatedtype Result

    func visit(_ item: ExprNode) -> Result
}

public protocol Visitable {
    func accept<T: Visitor>(visitor: T) -> T.Result
}

extension ExprNode {
    public func accept<T: Visitor>(visitor: T) -> T.Result {
        return visitor.visit(self)
    }
}

public struct NumberNode: ExprNode {
    public let string: String
    public let startToken: Token
    public var value: Float {
        (string as NSString).floatValue
    }
    public var fractionalDigits: Int {
        guard let bound = string.range(of: ".")?.upperBound else { return 0 }
        return string.utf8.distance(from: bound, to: string.endIndex)
    }
    public var integerDigits: Int {
        guard let bound = string.range(of: ".")?.lowerBound else { return 0 }
        return string.utf8.distance(from: string.startIndex, to: bound)
    }
    public var description: String {
        return "NumberNode(\(value))"
    }
}

public struct BracedNode: ExprNode {
    public let expressions: [ExprNode]
    public let startToken: Token
    public var description: String {
        return "BracedNode(\(expressions))"
    }
    public func unwrap() -> ExprNode? {
        if expressions.isEmpty {
            return nil
        } else if expressions.count == 1,
           let expr = expressions.first {
            return expr
        }
        return self
    }
}

public struct VariableNode: ExprNode {
    public let name: String
    public let subscripts: [ExprNode]
    public let startToken: Token
    public var description: String {
        return "VariableNode(\(name))"
    }
}

public struct TexNode: ExprNode {
    public let name: String
    public let arguments: [BracedNode]
    public let startToken: Token
    public var description: String {
        return "TexNode(\(name))"
    }
}

public struct TexListNode: ExprNode {
    public let name: String
    public let arguments: [String]
    public let expressions: [ExprNode]
    public let startToken: Token
    public var description: String {
        return "TexListNode(\(name))"
    }

    public struct TexListSuffix: ExprNode {
        public let name: String
        public let arguments: [String]
        public let startToken: Token
        public var description: String {
            return "TexListSuffix(\(name))"
        }
    }
}

public struct BinaryOpNode: ExprNode {
    public let op: Token.Symbol
    public let lhs: ExprNode
    public let rhs: ExprNode
    public let startToken: Token
    public var description: String {
        return "BinaryOpNode(\(op), lhs: \(lhs), rhs: \(rhs))"
    }
}

public struct UnaryOpNode: ExprNode {
    public let op: Token.Symbol
    public let expression: ExprNode
    public let startToken: Token
    public var description: String {
        return "UnaryOpNode(\(op))"
    }
}

public struct CallNode: ExprNode {
    public let callee: VariableNode
    public let arguments: [ExprNode]
    public let startToken: Token
    public var description: String {
        return "CallNode(name: \(callee), argument: \(arguments))"
    }
}

public struct PrototypeNode: CustomStringConvertible {
    public let name: VariableNode
    public let argumentNames: [VariableNode]
    public let startToken: Token
    public var description: String {
        return "PrototypeNode(name: \(name), argumentNames: \(argumentNames))"
    }
}

public struct FunctionNode: ExprNode {
    public let prototype: PrototypeNode
    public let body: ExprNode
    public let startToken: Token
    public var description: String {
        return "FunctionNode(prototype: \(prototype), body: \(body))"
    }
}
