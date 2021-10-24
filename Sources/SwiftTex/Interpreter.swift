//
//  Interpreter.swift
//  
//
//  Created by Adam Wulf on 10/24/21.
//

import Foundation

public enum InterpreterError: Error {
    case UnhandledExpression(token: Token)
    case InvalidOperator(token: Token)
}

public class Interpreter: Visitor {
    public typealias Result = Swift.Result<ExprNode, InterpreterError>

    private var globalScope: [VariableNode: ExprNode] = [:]

    private var scopes: [[VariableNode: ExprNode]] = []

    private var currentScope: [VariableNode: ExprNode] {
        return scopes.last ?? globalScope
    }

    public func visit(_ item: ExprNode) -> Result {
        switch item {
        case let item as NumberNode:
            return .success(item)
        case let item as VariableNode:
            if let val = currentScope[item] {
                return .success(val)
            } else {
                return .success(item)
            }
        case let item as UnaryOpNode:
            if let num = item.children.first as? NumberNode {
                switch item.op {
                case .plus:
                    return .success(num)
                case .minus:
                    return .success(-num)
                default:
                    return .failure(.InvalidOperator(token: item.startToken))
                }
            } else {
                return .success(item)
            }
        case let item as BinaryOpNode:
            let left = item.lhs.accept(visitor: self)
            let right = item.rhs.accept(visitor: self)
            switch (left, right) {
            case (.success(let lnum as NumberNode), .success(let rnum as NumberNode)):
                switch item.op {
                case .plus:
                    return .success(lnum + rnum)
                case .minus:
                    return .success(lnum - rnum)
                case .mult(implicit: _):
                    return .success(lnum * rnum)
                case .div:
                    return .success(lnum / rnum)
                case .exp:
                    return .success(lnum ^ rnum)
                case .equal:
                    return .success(BinaryOpNode(op: item.op, lhs: lnum, rhs: rnum, startToken: item.startToken))
                }
            case (.success(let left), .success(let right)):
                return .success(BinaryOpNode(op: item.op, lhs: left, rhs: right, startToken: item.startToken))
            case (.failure, _):
                return left
            case (_, .failure):
                return right
            }
        case let item as BracedNode:
            return .success(item)
        case let item as TexNode:
            return .success(item)
        case let item as TexListNode:
            return .success(item)
        case let item as FunctionNode:
            return .success(item)
        case let item as CallNode:
            return .success(item)
        default:
            return .failure(.UnhandledExpression(token: item.startToken))
        }
    }
}
