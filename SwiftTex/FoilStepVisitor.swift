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
            if item.op == .exp {
                if let exponent = item.rhs as? NumberNode {
                    if exponent.value < 0 {
                        let updated = BinaryOpNode(op: .exp, lhs: item.lhs, rhs: -exponent, startToken: item.startToken)
                        let div = BinaryOpNode(op: .div, lhs: NumberNode(string: "1", startToken: exponent.startToken),
                                               rhs: updated,
                                               startToken: item.startToken)
                        return singleStep ? div : div.accept(visitor: self)
                    } else if exponent.value == 1 {
                        return singleStep ? item.lhs : item.lhs.accept(visitor: self)
                    } else if exponent.value > 2 && exponent.fractionalDigits == 0 {
                        let updated = BinaryOpNode(op: .exp, lhs: item.lhs, rhs: exponent - 1, startToken: item.startToken)
                        return BinaryOpNode(op: .mult(implicit: true), lhs: item.lhs, rhs: updated, startToken: item.startToken)
                    } else if exponent.value > 1 && exponent.fractionalDigits == 0 {
                        return BinaryOpNode(op: .mult(implicit: true), lhs: item.lhs, rhs: item.lhs, startToken: item.startToken)
                    }
                }
            } else if
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
