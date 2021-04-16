//
//  AnonymousVisitor.swift
//  
//
//  Created by Adam Wulf on 4/16/21.
//

import Foundation

public class AnonymousVisitor: IdentityVisitor {

    let block: (ExprNode) -> ExprNode?

    public init(_ block: @escaping (ExprNode) -> ExprNode?) {
        self.block = block
    }

    private func visit(items: [ExprNode]) -> [ExprNode] {
        return items.map({ $0.accept(visitor: self) })
    }

    public override func visit(_ item: ExprNode) -> ExprNode {
        if let expr = block(item) {
            return expr
        }
        return super.visit(item)
    }
}
