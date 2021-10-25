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
    case UnknownFunctionName(token: Token, node: VariableNode)
    case IncorrectArgumentCount(token: Token)
}

struct Environment {
    private var globalScope: [VariableNode: ExprNode] = [:]

    private var scopes: [[VariableNode: ExprNode]] = []

    private var currentScope: [VariableNode: ExprNode] {
        return scopes.last ?? globalScope
    }

    var environment: [VariableNode: ExprNode] {
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

    var description: String {
        environment.reduce("") { (partialResult: String, pair: (key: VariableNode, value: ExprNode)) -> String in
            return partialResult + (partialResult.isEmpty ? "" : "\n") + pair.key.asTex + " => " + pair.value.asTex
        }
    }

    mutating func pushScope() {
        scopes.append([:])
    }

    mutating func popScope() {
        scopes.removeLast()
    }

    func lookup(variable: VariableNode) -> ExprNode? {
        for scope in ([globalScope] + scopes).reversed() {
            for (scoped, val) in scope {
                if scoped.matches(variable) {
                    return val
                }
            }
        }
        return nil
    }

    mutating func setScope(_ variable: VariableNode, _ expr: ExprNode) {
        if var last = scopes.last {
            last[variable] = expr
            scopes.removeLast()
            scopes.append(last)
        } else {
            globalScope[variable] = expr
        }
    }
}

public class Interpreter: Visitor {
    public typealias Result = Swift.Result<ExprNode, InterpreterError>

    var env = Environment()

    func pushScope<T>(_ block: () -> T) -> T {
        env.pushScope()
        let ret = block()
        env.popScope()
        return ret
    }

    public func visit(_ item: ExprNode) -> Result {
        switch item {
        case let item as NumberNode:
            return .success(item)
        case let item as VariableNode:
            if let val = env.lookup(variable: item) {
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
                let simpleLeft = left.accept(visitor: self)
                let simpleRight = right.accept(visitor: self)
                if case .success(let simpleLeft) = simpleLeft {
                    if case .success(let simpleRight) = simpleRight {
                        return .success(BinaryOpNode(op: item.op, lhs: simpleLeft, rhs: simpleRight, startToken: item.startToken))
                    } else {
                        return simpleRight
                    }
                } else {
                    return simpleLeft
                }
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
                    env.setScope(arg, arg)
                }
                let result = item.body.accept(visitor: self)
                if case .success(let simpleBody) = result {
                    return .success(FunctionNode(prototype: item.prototype, body: simpleBody, startToken: item.startToken))
                } else {
                    return result
                }
            }
            if case .success(let expr) = simplified {
                env.setScope(item.prototype.name, expr)
                return .success(expr)
            } else {
                return simplified
            }
        case let item as CallNode:
            guard
                let function = env.lookup(variable: item.callee) as? FunctionNode
            else {
                return .failure(.UnknownFunctionName(token: item.startToken, node: item.callee))
            }
            guard item.arguments.count <= function.prototype.argumentNames.count else {
                return .failure(.IncorrectArgumentCount(token: item.startToken))
            }

            if item.arguments.count == function.prototype.argumentNames.count {
                return pushScope { () -> Result in
                    for i in 0..<item.arguments.count {
                        let arg = item.arguments[i]
                        let name = function.prototype.argumentNames[i]
                        let argResult = arg.accept(visitor: self)
                        if case .success(let argResult) = argResult {
                            env.setScope(name, argResult)
                        } else {
                            return argResult
                        }
                    }
                    return function.body.accept(visitor: self)
                }
            } else {
                return .success(item)
            }
        default:
            return .failure(.UnhandledExpression(token: item.startToken))
        }
    }
}
