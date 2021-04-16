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
        case let unItem as UnaryOpNode:
            if let num = unItem.expression as? NumberNode {
                return NumberNode(string: unItem.op.rawValue + num.string, startToken: unItem.startToken)
            } else {
                return unItem
            }
        case let binItem as BinaryOpNode:
            var item = binItem
            if !singleStep {
                // if i'm not a single step, then i want to do depth first processing of the tree
                // otherwise, i just want to return immediately if possible after processing this node
                item = BinaryOpNode(op: item.op,
                                    lhs: item.lhs.accept(visitor: self),
                                    rhs: item.rhs.accept(visitor: self),
                                    startToken: item.startToken)
            }
            let multOp = Token.Symbol.mult(implicit: true)
            if item.op == .exp {
                if let exponent = item.rhs as? NumberNode {
                    if exponent.value == 0 {
                        return NumberNode(string: "1", startToken: item.startToken)
                    } else if exponent.value < 0 {
                        let updated = BinaryOpNode(op: .exp,
                                                   lhs: item.lhs,
                                                   rhs: -exponent,
                                                   startToken: item.startToken)
                        let div = BinaryOpNode(op: .div,
                                               lhs: NumberNode(string: "1", startToken: exponent.startToken),
                                               rhs: updated,
                                               startToken: item.startToken)
                        return singleStep ? div : div.accept(visitor: self)
                    } else if exponent.value == 2 {
                        let ret = BinaryOpNode(op: .mult(implicit: true),
                                            lhs: item.lhs,
                                            rhs: item.lhs,
                                            startToken: item.startToken)
                        return singleStep ? ret : ret.accept(visitor: self)
                    } else if exponent.value == 1 {
                        return item.lhs.accept(visitor: self)
                    } else if exponent.value > 1 {
                        let updated = BinaryOpNode(op: .exp, lhs: item.lhs, rhs: exponent - 1, startToken: item.startToken)
                        let ret = BinaryOpNode(op: .mult(implicit: true),
                                            lhs: item.lhs,
                                            rhs: updated,
                                            startToken: item.startToken)
                        return singleStep ? ret : ret.accept(visitor: self)
                    }
                }
            } else if
                item.op == .mult(),
                let factor = item.lhs as? BinaryOpNode,
                factor.op == .plus || factor.op == .minus {
                let term1 = BinaryOpNode(op: multOp, lhs: factor.lhs, rhs: item.rhs, startToken: factor.lhs.startToken)
                let term2 = BinaryOpNode(op: multOp, lhs: factor.rhs, rhs: item.rhs, startToken: factor.rhs.startToken)
                let ret = BinaryOpNode(op: factor.op, lhs: term1, rhs: term2, startToken: item.startToken)
                return singleStep ? ret : ret.accept(visitor: self)
            } else if
                item.op == .mult(),
                let factor = item.rhs as? BinaryOpNode,
                factor.op == .plus || factor.op == .minus {
                let term1 = BinaryOpNode(op: multOp, lhs: item.lhs, rhs: factor.lhs, startToken: factor.lhs.startToken)
                let term2 = BinaryOpNode(op: multOp, lhs: item.lhs, rhs: factor.rhs, startToken: factor.rhs.startToken)
                let ret = BinaryOpNode(op: factor.op, lhs: term1, rhs: term2, startToken: item.startToken)
                return singleStep ? ret : ret.accept(visitor: self)
            }

            return super.visit(item)
        default:
            return super.visit(item)
        }
    }
}
