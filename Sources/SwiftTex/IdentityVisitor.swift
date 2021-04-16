//
//  IdentityVisitor.swift
//  SwiftTex
//
//  Created by Adam Wulf on 12/6/20.
//

import Foundation

public class IdentityVisitor: Visitor {

    public init() {
        // noop
    }

    private func visit(items: [ExprNode]) -> [ExprNode] {
        return items.map({ $0.accept(visitor: self) })
    }

    public func visit(_ item: ExprNode) -> ExprNode {
        switch item {
        case let item as NumberNode:
            return item
        case let item as VariableNode:
            return VariableNode(name: item.name, subscripts: item.subscripts.accept(visitor: self), startToken: item.startToken)
        case let item as UnaryOpNode:
            return UnaryOpNode(op: item.op,
                                expression: item.expression.accept(visitor: self),
                                startToken: item.startToken)
        case let item as BinaryOpNode:
            return BinaryOpNode(op: item.op,
                                lhs: item.lhs.accept(visitor: self),
                                rhs: item.rhs.accept(visitor: self),
                                startToken: item.startToken)
        case let item as BracedNode:
            return BracedNode(expressions: item.expressions.accept(visitor: self), startToken: item.startToken)
        case let item as TexNode:
            let args = item.arguments.accept(visitor: self).compactMap { (node) -> BracedNode? in
                assert(node is BracedNode)
                return node as? BracedNode
            }
            return TexNode(name: item.name, arguments: args, startToken: item.startToken)
        case let item as TexListNode:
            return TexListNode(name: item.name,
                               arguments: item.arguments,
                               expressions: item.expressions.accept(visitor: self),
                               startToken: item.startToken)
        case let item as FunctionNode:
            guard
                let name = item.prototype.name.accept(visitor: self) as? VariableNode,
                let arguments = item.prototype.argumentNames.accept(visitor: self) as? [VariableNode]
            else { return item }
            return FunctionNode(prototype: PrototypeNode(name: name,
                                                         argumentNames: arguments,
                                                         startToken: item.prototype.startToken),
                                body: item.body.accept(visitor: self),
                                startToken: item.startToken)
        case let item as CallNode:
            guard
                let name = item.callee.accept(visitor: self) as? VariableNode,
                let arguments = item.arguments.accept(visitor: self) as? [VariableNode]
            else { return item }
            return CallNode(callee: name, arguments: arguments, startToken: item.startToken)
        default:
            return item
        }
    }
}
