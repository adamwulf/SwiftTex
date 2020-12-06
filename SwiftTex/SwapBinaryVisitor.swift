//
//  SwapBinaryVisitor.swift
//  SwiftTex
//
//  Created by Adam Wulf on 12/6/20.
//

import Foundation

class SwapBinaryVisitor: Visitor {
    var ignoreSubscripts: Bool = true

    private func visit(items: [ExprNode]) -> [ExprNode] {
        return items.map({ $0.accept(visitor: self) })
    }

    func visit(_ item: ExprNode) -> ExprNode {
        switch item {
        case let item as NumberNode:
            return item
        case let item as VariableNode:
            if ignoreSubscripts || item.subscripts.isEmpty {
                return item
            } else {
                return VariableNode(name: item.name, subscripts: item.subscripts.accept(visitor: self), startToken: item.startToken)
            }
        case let item as BinaryOpNode:
            return BinaryOpNode(op: item.op,
                                lhs: item.rhs.accept(visitor: self),
                                rhs: item.lhs.accept(visitor: self),
                                startToken: item.startToken)
        case let item as BracedNode:
            return BracedNode(expressions: item.expressions.accept(visitor: self), startToken: item.startToken)
        case let item as TexNode:
            return TexNode(name: item.name, arguments: item.arguments.accept(visitor: self), startToken: item.startToken)
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
