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

    func visit(_ item: ExprNode) -> String {
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
            if item.op == " " {
                // implicit multiplication
                return "(" + item.lhs.accept(visitor: self) + ")(" + item.rhs.accept(visitor: self) + ")"
            } else {
                return item.lhs.accept(visitor: self) + " \(item.op) " + item.rhs.accept(visitor: self)
            }
        case let item as BracedNode:
            return "{ " + self.visit(items: item.expressions).joined(separator: " ") + " }"
        case let item as TexNode:
            return "\\\(item.name)" + self.visit(items: item.arguments).map({ "{ \($0) }" }).joined()
        case let item as FunctionNode:
            let name = item.prototype.name.accept(visitor: self)
            let args = self.visit(items: item.prototype.argumentNames).joined(separator: ", ")
            let body = item.body.accept(visitor: self)
            return "\(name)(\(args)) = \(body)"
        case let item as CallNode:
            let name = item.callee.accept(visitor: self)
            let args = self.visit(items: item.arguments).joined(separator: ", ")
            return "\(name)(\(args))"
        default:
            return "\\undefined{ \(String(describing: type(of: item))) }"
        }
    }
}