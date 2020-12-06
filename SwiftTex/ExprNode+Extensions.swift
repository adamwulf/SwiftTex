//
//  ExprNode+Extensions.swift
//  SwiftTex
//
//  Created by Adam Wulf on 12/6/20.
//

import Foundation

extension Array where Element == ExprNode {
    func accept<T: Visitor>(visitor: T) -> [T.Result] {
        map({ $0.accept(visitor: visitor) })
    }
}

extension Array where Element: ExprNode {
    func accept<T: Visitor>(visitor: T) -> [T.Result] {
        map({ $0.accept(visitor: visitor) })
    }
}
