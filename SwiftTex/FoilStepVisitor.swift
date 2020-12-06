//
//  FoilVisitor.swift
//  SwiftTex
//
//  Created by Adam Wulf on 12/6/20.
//

import Foundation

class FoilVisitor: IdentityVisitor {
    override func visit(_ item: ExprNode) -> ExprNode {
        switch item {
        case let item as BinaryOpNode:
            if
                item.op == .mult(),
                let factor = item.lhs as? BinaryOpNode,
                factor.op == .plus {
                let term1 = BinaryOpNode(op: .mult(), lhs: factor.lhs, rhs: item.rhs, startToken: factor.lhs.startToken)
                let term2 = BinaryOpNode(op: .mult(), lhs: factor.rhs, rhs: item.rhs, startToken: factor.rhs.startToken)
                return BinaryOpNode(op: .plus,
                                    lhs: term1.accept(visitor: self),
                                    rhs: term2.accept(visitor: self),
                                    startToken: item.startToken)
            } else if
                item.op == .mult(),
                let factor = item.rhs as? BinaryOpNode,
                factor.op == .plus {
                let term1 = BinaryOpNode(op: .mult(), lhs: item.lhs, rhs: factor.lhs, startToken: factor.lhs.startToken)
                let term2 = BinaryOpNode(op: .mult(), lhs: item.lhs, rhs: factor.rhs, startToken: factor.rhs.startToken)
                return BinaryOpNode(op: .plus,
                                    lhs: term1.accept(visitor: self),
                                    rhs: term2.accept(visitor: self),
                                    startToken: item.startToken)
            }

            return item
        default:
            return super.visit(item)
        }
    }
}
