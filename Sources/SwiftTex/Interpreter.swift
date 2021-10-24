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
    case UnexpectedNode(token: Token, node: ExprNode)
}

public class Interpreter: Visitor {
    public typealias Result = Swift.Result<ExprNode, InterpreterError>

    private var globalScope: [VariableNode: ExprNode] = [:]

    private var scopes: [[VariableNode: ExprNode]] = []

    private var currentScope: [VariableNode: ExprNode] {
        return scopes.last ?? globalScope
    }

    public var environment: [VariableNode: ExprNode] {
        let allScopes = [globalScope] + scopes
        var ret: [VariableNode: ExprNode] = [:]
        for scope in allScopes.reversed() {
            for (variable, val) in scope {
                if ret[variable] == nil {
                    ret[variable] = val
                }
            }
        }
        return ret
    }

    private func pushScope<T>(in block: () -> T) -> T {
        scopes.append([:])
        let ret = block()
        scopes.removeLast()
        return ret
    }

    private func lookup(variable: VariableNode) -> ExprNode? {
        for scope in ([globalScope] + scopes).reversed() {
            if let val = scope[variable] {
                return val
            }
        }
        return nil
    }

    func setScope(_ variable: VariableNode, _ expr: ExprNode) {
        if var last = scopes.last {
            last[variable] = expr
            scopes.removeLast()
            scopes.append(last)
        } else {
            globalScope[variable] = expr
        }
    }

    public func visit(_ item: ExprNode) -> Result {
        switch item {
        case let item as NumberNode:
            return .success(item)
        case let item as VariableNode:
            if let val = lookup(variable: item) {
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
            return .failure(.UnexpectedNode(token: item.startToken, node: item))
        case let item as TexNode:
            return .failure(.UnexpectedNode(token: item.startToken, node: item))
        case let item as TexListNode:
            return .failure(.UnexpectedNode(token: item.startToken, node: item))
        case let item as FunctionNode:
            let simplified = pushScope { () -> Result in
                for arg in item.prototype.argumentNames {
                    setScope(arg, arg)
                }
                let result = item.body.accept(visitor: self)
                if case .success(let simpleBody) = result {
                    return .success(FunctionNode(prototype: item.prototype, body: simpleBody, startToken: item.startToken))
                } else {
                    return result
                }
            }
            if case .success(let expr) = simplified {
                setScope(item.prototype.name, expr)
                return .success(expr)
            } else {
                return simplified
            }
        case let item as CallNode:
            return .success(item)
        default:
            return .failure(.UnhandledExpression(token: item.startToken))
        }
    }
}
