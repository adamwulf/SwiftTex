//
//  PrintVisitor.swift
//  SwiftTex
//
//  Created by Adam Wulf on 12/6/20.
//

import Foundation

class PrintVisitor: Visitor {
    var ignoreSubscripts: Bool = true

    private func visit(items: [ExprNode]) -> [String] {
        return items.map({ $0.accept(visitor: self) })
    }

    func visit<ItemType>(_ item: ItemType) -> String where ItemType: Visitable {
        switch item {
        case let item as NumberNode:
            let formatter = NumberFormatter()
            formatter.minimumFractionDigits = item.fractionalDigits
            return formatter.string(from: item.value as NSNumber) ?? "\\formatError{\(item.value)}"
        case let item as VariableNode:
            if ignoreSubscripts || item.subscripts.isEmpty {
                return item.name
            } else {
                return item.name + "_{" + self.visit(items: item.subscripts).joined() + "}"
            }
        case let item as BinaryOpNode:
            let op = item.op == " " ? item.op : " \(item.op) "
            return item.lhs.accept(visitor: self) + op + item.rhs.accept(visitor: self)
        case let item as BracedNode:
            return "{ " + self.visit(items: item.expressions).joined(separator: " ") + " }"
        case let item as TexNode:
            return "\\\(item.name)" + self.visit(items: item.arguments).map({ "{ \($0) }" }).joined()
        default:
            return "\\undefined{ \(String(describing: type(of: item))) }"
        }
    }
}
