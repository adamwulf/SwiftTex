//
//  SwapBinaryVisitor.swift
//  SwiftTex
//
//  Created by Adam Wulf on 12/6/20.
//

import Foundation

public class SwapBinaryVisitor: IdentityVisitor {

    override public func visit(_ item: ExprNode) -> ExprNode {
        switch item {
        case let item as BinaryOpNode:
            return BinaryOpNode(op: item.op,
                                lhs: item.rhs.accept(visitor: self),
                                rhs: item.lhs.accept(visitor: self),
                                startToken: item.startToken)
        default:
            return super.visit(item)
        }
    }
}
