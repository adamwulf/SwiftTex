//
//  FoilStepVisitor.swift
//  SwiftTex
//
//  Created by Adam Wulf on 12/6/20.
//

import Foundation

class FoilStepVisitor: IdentityVisitor {
    override func visit(_ item: ExprNode) -> ExprNode {
        switch item {
        case let item as BinaryOpNode:
            if
                item.op == "*" || item.op == " ",
                let factor = item.lhs as? BinaryOpNode,
                factor.op == "+" {
                let term1 = BinaryOpNode(op: "*", lhs: factor.lhs, rhs: item.rhs, startToken: factor.lhs.startToken)
                let term2 = BinaryOpNode(op: "*", lhs: factor.rhs, rhs: item.rhs, startToken: factor.rhs.startToken)
                return BinaryOpNode(op: "+", lhs: term1, rhs: term2, startToken: item.startToken)
            }
            return item
        default:
            return super.visit(item)
        }
    }
}
