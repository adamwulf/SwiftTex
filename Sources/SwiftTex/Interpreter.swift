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
    case EmptyListNode(token: Token)
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
            let leftResult = item.lhs.accept(visitor: self)
            let rightResult = item.rhs.accept(visitor: self)
            switch (leftResult, rightResult) {
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
                return leftResult
            case (_, .failure):
                return rightResult
            }
        case let item as BracedNode:
            return .failure(.UnexpectedNode(token: item.startToken, node: item))
        case let item as LetNode:
            env.set(item.variable, to: item.value)
            return .success(item.variable)
        case let item as TexNode:
            return .failure(.UnexpectedNode(token: item.startToken, node: item))
        case let item as TexListNode:
            if let result = item.children.map({ $0.accept(visitor: self) }).last {
                return result
            } else {
                return .failure(.EmptyListNode(token: item.startToken))
            }
        case let item as FunctionNode:
            let simplified = pushScope { () -> Result in
                for arg in item.prototype.argumentNames {
                    env.set(arg, to: arg)
                }
                let result = item.body.accept(visitor: self)
                if case .success(let simpleBody) = result {
                    return .success(FunctionNode(prototype: item.prototype, body: simpleBody, closed: [:], startToken: item.startToken))
                } else {
                    return result
                }
            }
            if case .success(let expr) = simplified {
                env.set(item.prototype.name, to: expr)
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
                            env.set(name, to: argResult)
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
