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
    var children: [ExprNode] { get }

    func matches(_ other: ExprNode) -> Bool
}

extension ExprNode {
    var asTex: String {
        return accept(visitor: PrintVisitor())
    }
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
    public let children: [ExprNode] = []
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
    public func matches(_ other: ExprNode) -> Bool {
        guard let other = other as? NumberNode else { return false }
        return value == other.value
    }
}

public struct BracedNode: ExprNode {
    public let children: [ExprNode]
    public let startToken: Token
    public var description: String {
        return "BracedNode(\(children))"
    }
    public func unwrap() -> ExprNode? {
        if children.isEmpty {
            return nil
        } else if children.count == 1,
           let expr = children.first {
            return expr
        }
        return self
    }
    public func matches(_ other: ExprNode) -> Bool {
        guard
            let other = other as? BracedNode,
            children.count == other.children.count
        else { return false }
        var otherKids = other.children
        for child in children {
            guard let index = otherKids.firstIndex(where: { $0.matches(child) }) else { return false }
            otherKids.remove(at: index)
        }
        return true
    }
}

public struct VariableNode: ExprNode {
    public let name: String
    public let subscripts: [ExprNode]
    public let startToken: Token
    public let children: [ExprNode] = []
    public var description: String {
        return "VariableNode(\(name))"
    }

    public func matches(_ other: ExprNode) -> Bool {
        guard
            let other = other as? VariableNode,
            subscripts.count == other.subscripts.count,
            name == other.name
        else { return false }
        var otherSubs = other.subscripts
        for child in subscripts {
            guard let index = otherSubs.firstIndex(where: { $0.matches(child) }) else { return false }
            otherSubs.remove(at: index)
        }
        return true
    }
}

public struct LetNode: ExprNode {
    public let variable: VariableNode
    public let value: ExprNode
    public let startToken: Token
    public var children: [ExprNode] {
        return [variable, value]
    }
    public var description: String {
        return "LetNode(\(variable.name))"
    }
    public func matches(_ other: ExprNode) -> Bool {
        assertionFailure()
        return false
    }
}

public struct TexNode: ExprNode {
    public let name: String
    public let arguments: [BracedNode]
    public let startToken: Token
    public let children: [ExprNode] = []
    public var description: String {
        return "TexNode(\(name))"
    }
    public func matches(_ other: ExprNode) -> Bool {
        assertionFailure()
        return false
    }
}

extension VariableNode: Hashable {
    public static func == (lhs: VariableNode, rhs: VariableNode) -> Bool {
        return lhs.startToken == rhs.startToken
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(startToken.col)
        hasher.combine(startToken.line)
        hasher.combine(startToken.loc)
        hasher.combine(startToken.raw)
        hasher.combine(startToken.range.lowerBound)
        hasher.combine(startToken.range.upperBound)
    }
}

public struct TexListNode: ExprNode {
    public let name: String
    public let arguments: [String]
    public let children: [ExprNode]
    public let startToken: Token
    public var description: String {
        return "TexListNode(\(name))"
    }
    public func matches(_ other: ExprNode) -> Bool {
        assertionFailure()
        return false
    }
}

public struct BinaryOpNode: ExprNode {
    public let op: Token.Symbol
    public let lhs: ExprNode
    public let rhs: ExprNode
    public var children: [ExprNode] {
        return [lhs, rhs]
    }
    public let startToken: Token
    public var description: String {
        return "BinaryOpNode(\(op), lhs: \(lhs), rhs: \(rhs))"
    }
    public func matches(_ other: ExprNode) -> Bool {
        guard let other = other as? BinaryOpNode else { return false }
        return op == other.op && lhs.matches(other.lhs) && rhs.matches(other.rhs)
    }
}

public struct UnaryOpNode: ExprNode {
    public let op: Token.Symbol
    public let expression: ExprNode
    public var children: [ExprNode] {
        return [expression]
    }
    public let startToken: Token
    public var description: String {
        return "UnaryOpNode(\(op))"
    }
    public func matches(_ other: ExprNode) -> Bool {
        guard let other = other as? UnaryOpNode else { return false }
        return op == other.op && expression.matches(other.expression)
    }
}

public struct CallNode: ExprNode {
    public let callee: ExprNode
    public let arguments: [ExprNode]
    public var children: [ExprNode] {
        return [callee] + arguments
    }
    public let startToken: Token
    public var description: String {
        return "CallNode(closure: \(callee), argument: \(arguments))"
    }
    public func matches(_ other: ExprNode) -> Bool {
        assertionFailure()
        return false
    }
}

public struct PrototypeNode: ExprNode {
    public let argumentNames: [VariableNode]
    public let startToken: Token
    public var children: [ExprNode] {
        return argumentNames
    }
    public var description: String {
        return "PrototypeNode(\(argumentNames))"
    }
    public func matches(_ other: ExprNode) -> Bool {
        guard let other = other as? PrototypeNode else { return false }
        guard
            argumentNames.count == other.argumentNames.count
        else { return false }
        var otherArgs = other.argumentNames
        for arg in argumentNames {
            guard let index = otherArgs.firstIndex(where: { $0.matches(arg) }) else { return false }
            otherArgs.remove(at: index)
        }
        return true
    }
}

public struct ClosureNode: ExprNode {
    public let prototype: PrototypeNode
    public let body: ExprNode
    public let closed: Environment
    public let startToken: Token
    public var children: [ExprNode] {
        return [prototype, body]
    }
    public var description: String {
        return "ClosureNode(prototype: \(prototype), body: \(body))"
    }
    public func matches(_ other: ExprNode) -> Bool {
        guard let other = other as? ClosureNode else { return false }
        return prototype.matches(other.prototype) && body.matches(other.body)
    }
}
