//
//  PrintVisitor.swift
//  SwiftTex
//
//  Created by Adam Wulf on 12/6/20.
//

import Foundation

public class PrintVisitor: Visitor {
    public var ignoreSubscripts: Bool = false

    public init() {
        // noop
    }

    private func visit(items: [ExprNode]) -> [String] {
        return items.map({ $0.accept(visitor: self) })
    }

    public func visit(_ item: ExprNode) -> String {
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
            if case .mult(let implicit) = item.op,
               implicit {
                // implicit multiplication
                func needsParens(_ expr: ExprNode) -> Bool {
                    if let bin = expr as? BinaryOpNode {
                        return item.op.precedence > bin.op.precedence
                    }
                    if item.lhs as? NumberNode != nil,
                       item.rhs as? NumberNode != nil {
                        return true
                    }
                    return false
                }
                let lhs = item.lhs.accept(visitor: self)
                let rhs = item.rhs.accept(visitor: self)
                let plhs = needsParens(item.lhs) ? "(\(lhs))" : lhs
                let prhs = needsParens(item.rhs) ? "(\(rhs))" : rhs

                return plhs + prhs
            } else {
                func needsParens(_ expr: ExprNode) -> Bool {
                    if let bin = expr as? BinaryOpNode {
                        return item.op.precedence > bin.op.precedence
                    }
                    return false
                }
                let lhs = item.lhs.accept(visitor: self)
                let rhs = item.rhs.accept(visitor: self)
                let plhs = needsParens(item.lhs) ? "(\(lhs))" : lhs
                let prhs = needsParens(item.rhs) ? "(\(rhs))" : rhs
                return plhs + " \(item.op.rawValue) " + prhs
            }
        case let item as BracedNode:
            return "{ " + self.visit(items: item.expressions).joined(separator: " ") + " }"
        case let item as TexNode:
            return "\\\(item.name)" + self.visit(items: item.arguments).map({ "{ \($0) }" }).joined()
        case let item as TexListNode:
            let begin = "\\begin{\(item.name)}"
            let end = "\\end{\(item.name)}"
            let args = item.arguments[1...].map({ "{\($0)}" }).joined()
            let exps = self.visit(items: item.expressions)
            return ([begin + args] + exps + [end]).joined(separator: "\n")
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
