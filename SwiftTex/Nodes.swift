//
//  Nodes.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

public protocol ExprNode: CustomStringConvertible {
}

public struct NumberNode: ExprNode {
    public let value: Float
    public var description: String {
        return "NumberNode(\(value))"
    }
}

public struct BracedNode: ExprNode {
    public let expressions: [ExprNode]
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
    public var description: String {
        return "VariableNode(\(name))"
    }
}

public struct TexNode: ExprNode {
    public let name: String
    public let arguments: [ExprNode]
    public var description: String {
        return "TexNode(\(name))"
    }
}

public struct BinaryOpNode: ExprNode {
    public let op: String
    public let lhs: ExprNode
    public let rhs: ExprNode
    public var description: String {
        return "BinaryOpNode(\(op), lhs: \(lhs), rhs: \(rhs))"
    }
}

public struct CallNode: ExprNode {
    public let callee: VariableNode
    public let arguments: [ExprNode]
    public var description: String {
        return "CallNode(name: \(callee), argument: \(arguments))"
    }
}

public struct PrototypeNode: CustomStringConvertible {
    public let name: VariableNode
    public let argumentNames: [VariableNode]
    public var description: String {
        return "PrototypeNode(name: \(name), argumentNames: \(argumentNames))"
    }
}

public struct FunctionNode: ExprNode {
    public let prototype: PrototypeNode
    public let body: ExprNode
    public var description: String {
        return "FunctionNode(prototype: \(prototype), body: \(body))"
    }
}
