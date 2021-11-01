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
            return BracedNode(children: item.children.accept(visitor: self), startToken: item.startToken)
        case let item as TexNode:
            let args = item.arguments.accept(visitor: self).compactMap { (node) -> BracedNode? in
                assert(node is BracedNode)
                return node as? BracedNode
            }
            return TexNode(name: item.name, arguments: args, startToken: item.startToken)
        case let item as TexListNode:
            return TexListNode(name: item.name,
                               arguments: item.arguments,
                               children: item.children.accept(visitor: self),
                               startToken: item.startToken)
        case let item as ClosureNode:
            guard
                let arguments = item.prototype.argumentNames.accept(visitor: self) as? [VariableNode]
            else { return item }
            return ClosureNode(prototype: PrototypeNode(argumentNames: arguments,
                                                        startToken: item.prototype.startToken),
                               body: item.body.accept(visitor: self),
                               closed: item.closed,
                               startToken: item.startToken)
        case let item as CallNode:
            guard
                let callee = item.callee.accept(visitor: self) as? ClosureNode,
                let arguments = item.arguments.accept(visitor: self) as? [VariableNode]
            else { return item }
            return CallNode(callee: callee, arguments: arguments, startToken: item.startToken)
        default:
            return item
        }
    }
}
