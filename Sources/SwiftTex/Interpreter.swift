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
        case let num as NumberNode:
            return .success(num)
        case let variable as VariableNode:
            if let val = env.lookup(variable: variable) {
                return .success(val)
            } else {
                return .success(variable)
            }
        case let unop as UnaryOpNode:
            if let num = unop.children.first as? NumberNode {
                switch unop.op {
                case .plus:
                    return .success(num)
                case .minus:
                    return .success(-num)
                default:
                    return .failure(.InvalidOperator(token: unop.startToken))
                }
            } else {
                return .success(unop)
            }
        case let binop as BinaryOpNode:
            let leftResult = binop.lhs.accept(visitor: self)
            let rightResult = binop.rhs.accept(visitor: self)
            switch (leftResult, rightResult) {
            case (.success(let lnum as NumberNode), .success(let rnum as NumberNode)):
                switch binop.op {
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
                    return .success(BinaryOpNode(op: binop.op, lhs: lnum, rhs: rnum, startToken: binop.startToken))
                }
            case (.success(let left), .success(let right)):
                return .success(BinaryOpNode(op: binop.op, lhs: left, rhs: right, startToken: binop.startToken))
            case (.failure, _):
                return leftResult
            case (_, .failure):
                return rightResult
            }
        case let braced as BracedNode:
            return .failure(.UnexpectedNode(token: braced.startToken, node: braced))
        case let letnode as LetNode:
            let result = letnode.value.accept(visitor: self)
            switch result {
            case .success(let result):
                env.set(letnode.variable, to: result)
                return .success(LetNode(variable: letnode.variable, value: result, startToken: letnode.startToken))
            case .failure:
                return result
            }
        case let tex as TexNode:
            return .failure(.UnexpectedNode(token: tex.startToken, node: tex))
        case let texlist as TexListNode:
            if let result = texlist.children.map({ $0.accept(visitor: self) }).last {
                return result
            } else {
                return .failure(.EmptyListNode(token: texlist.startToken))
            }
        case let closure as ClosureNode:
            let simplified = pushScope { () -> Result in
                for arg in closure.prototype.argumentNames {
                    env.set(arg, to: arg)
                }
                let result = closure.body.accept(visitor: self)
                if case .success(let simpleBody) = result {
                    return .success(ClosureNode(prototype: closure.prototype, body: simpleBody, closed: env, startToken: closure.startToken))
                } else {
                    return result
                }
            }
            if case .success(let expr) = simplified {
                return .success(expr)
            } else {
                return simplified
            }
        case let call as CallNode:
            guard
                case .success(let callee) = call.callee.accept(visitor: self),
                let callee = callee as? ClosureNode
            else { return .success(call) }
            guard call.arguments.count <= callee.prototype.argumentNames.count else {
                return .failure(.IncorrectArgumentCount(token: call.startToken))
            }

            if call.arguments.count == callee.prototype.argumentNames.count {
                var arguments: [VariableNode: ExprNode] = [:]
                for i in 0..<call.arguments.count {
                    let arg = call.arguments[i]
                    let name = callee.prototype.argumentNames[i]
                    let argResult = arg.accept(visitor: self)
                    if case .success(let argResult) = argResult {
                        arguments[name] = argResult
                    } else {
                        return argResult
                    }
                }

                return pushScope { () -> Result in
                    for (variable, value) in callee.closed.environment {
                        env.set(variable, to: value)
                    }
                    for (variable, value) in arguments {
                        env.set(variable, to: value)
                    }

                    return callee.body.accept(visitor: self)
                }
            } else {
                var closed = Environment()

                for i in 0..<call.arguments.count {
                    let arg = call.arguments[i]
                    let name = callee.prototype.argumentNames[i]
                    let argResult = arg.accept(visitor: self)
                    if case .success(let argResult) = argResult {
                        closed.set(name, to: argResult)
                    } else {
                        return argResult
                    }
                }

                return pushScope {
                    for (variable, value) in closed.environment {
                        env.set(variable, to: value)
                    }
                    let bodyResult = callee.body.accept(visitor: self)

                    switch bodyResult {
                    case .success(let updatedBody):
                        let updatedArgs = Array(callee.prototype.argumentNames[call.arguments.count...])
                        return .success(ClosureNode(prototype: PrototypeNode(argumentNames: updatedArgs, startToken: updatedArgs.first!.startToken),
                                                    body: updatedBody,
                                                    closed: closed,
                                                    startToken: callee.startToken))
                    case .failure:
                        return bodyResult
                    }
                }
            }
        default:
            return .failure(.UnhandledExpression(token: item.startToken))
        }
    }
}
