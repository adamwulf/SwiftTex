//
//  FoilVisitor.swift
//  SwiftTex
//
//  Created by Adam Wulf on 12/6/20.
//

import Foundation

public class FoilVisitor: IdentityVisitor {

    public var singleStep = false

    override public func visit(_ item: ExprNode) -> ExprNode {
        switch item {
        case let item as BinaryOpNode:
            let multOp = Token.Symbol.mult(implicit: true)
            if
                item.op == .mult(),
                let factor = item.lhs as? BinaryOpNode,
                factor.op == .plus || factor.op == .minus {
                let term1 = BinaryOpNode(op: multOp, lhs: factor.lhs, rhs: item.rhs, startToken: factor.lhs.startToken)
                let term2 = BinaryOpNode(op: multOp, lhs: factor.rhs, rhs: item.rhs, startToken: factor.rhs.startToken)
                return BinaryOpNode(op: factor.op,
                                    lhs: singleStep ? term1 : term1.accept(visitor: self),
                                    rhs: singleStep ? term2 : term2.accept(visitor: self),
                                    startToken: item.startToken)
            } else if
                item.op == .mult(),
                let factor = item.rhs as? BinaryOpNode,
                factor.op == .plus || factor.op == .minus {
                let term1 = BinaryOpNode(op: multOp, lhs: item.lhs, rhs: factor.lhs, startToken: factor.lhs.startToken)
                let term2 = BinaryOpNode(op: multOp, lhs: item.lhs, rhs: factor.rhs, startToken: factor.rhs.startToken)
                return BinaryOpNode(op: factor.op,
                                    lhs: singleStep ? term1 : term1.accept(visitor: self),
                                    rhs: singleStep ? term2 : term2.accept(visitor: self),
                                    startToken: item.startToken)
            }

            return super.visit(item)
        default:
            return super.visit(item)
        }
    }
}
