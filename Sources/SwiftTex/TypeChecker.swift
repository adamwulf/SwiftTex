//
//  TypeChecker.swift
//  
//
//  Created by Adam Wulf on 10/27/21.
//

import Foundation

public enum TypeCheckerError: Error {
    case ExpectedNumber(token: Token, given: TypeChecker.ValueType)
    case ExpectedFunction(token: Token, given: TypeChecker.ValueType)
    case UnexpectedType(token: Token, given: TypeChecker.ValueType)
    case EmptyListNode(token: Token)
    case InvalidArgumentCount(token: Token, given: Int, expected: Int)
    case UnhandledExpression(token: Token)
}

public class TypeChecker: Visitor {
    public typealias Result = Swift.Result<ValueType, TypeCheckerError>

    private var anonCount: Int = 0
    private func anonName() -> String {
        defer {
            anonCount += 1
        }
        return "anon\(anonCount)"
    }

    public enum ValueType: CustomStringConvertible {
        case number(node: ExprNode)
        case variable(node: ExprNode)
        case function(node: FunctionNode, arguments: Int)
        case unknown(node: ExprNode)

        public var description: String {
            switch self {
            case .number(let node):
                return "number(\(node.asTex))"
            case .variable(let node):
                return "variable(\(node.asTex))"
            case .function(let node, let args):
                return "function(\(node.asTex), \(args)"
            case .unknown(let node):
                return "unknown(\(node.asTex))"
            }
        }
    }

    var env = TypeEnvironment()

    func pushScope<T>(_ block: () -> T) -> T {
        env.pushScope()
        let ret = block()
        env.popScope()
        return ret
    }

    public func visit(_ item: ExprNode) -> Result {
        switch item {
        case let item as NumberNode:
            return .success(.number(node: item))
        case let item as VariableNode:
            if let val = env.lookup(variable: item) {
                return .success(val)
            } else {
                return .success(.unknown(node: item))
            }
        case let item as UnaryOpNode:
            let result = item.expression.accept(visitor: self)
            if case .success(let result) = result {
                if case .number = result {
                    return .success(.number(node: item))
                } else if case .variable = result {
                    return .success(.variable(node: item))
                } else {
                    return .failure(.UnexpectedType(token: item.startToken, given: result))
                }
            } else {
                return result
            }
        case let item as BinaryOpNode:
            let leftResult = item.lhs.accept(visitor: self)
            let rightResult = item.rhs.accept(visitor: self)
            switch (leftResult, rightResult) {
            case (.success(let lnum), .success(let rnum)):
                switch (lnum, rnum) {
                case (.number, .function):
                    fallthrough
                case (.variable, .function):
                    return .failure(.UnexpectedType(token: item.rhs.startToken, given: rnum))
                case (.function, .number):
                    fallthrough
                case (.function, .variable):
                    return .failure(.UnexpectedType(token: item.lhs.startToken, given: rnum))
                default:
                    return .success(.number(node: item))
                }
            case (.failure, _):
                return leftResult
            case (_, .failure):
                return rightResult
            }
        case let item as LetNode:
            let value = item.value.accept(visitor: self)
            if case .success(let value) = value {
                env.set(item.variable, to: value)
            }
            return value
        case _ as BracedNode, _ as TexNode, _ as TexListNode:
            let results = item.children.map({ $0.accept(visitor: self) })
            guard let last = results.last else { return .failure(.EmptyListNode(token: item.startToken)) }
            if let failure = results.first(where: { if case .failure = $0 { return true } else { return false } }) {
                return failure
            } else {
                return last
            }
        case let item as FunctionNode:
            let val = ValueType.function(node: item, arguments: item.prototype.argumentNames.count)
            env.set(item.prototype.name, to: val)
            return .success(val)
        case let item as CallNode:
            let envValue = env.lookup(variable: item.callee)
            guard
                case .function(let function, let argCount) = envValue
            else {
                if let envValue = envValue {
                    return .failure(.ExpectedFunction(token: item.startToken, given: envValue))
                } else {
                    return .success(.unknown(node: item))
                }
            }
            guard item.arguments.count <= argCount else {
                return .failure(.InvalidArgumentCount(token: item.startToken, given: item.arguments.count, expected: argCount))
            }

            if item.arguments.count == argCount {
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
                return pushScope { () -> Result in
                    var closedLet: [VariableNode: ExprNode] = [:]
                    for i in 0..<item.arguments.count {
                        let arg = item.arguments[i]
                        let name = function.prototype.argumentNames[i]
                        let argResult = arg.accept(visitor: self)
                        if case .success(let argResult) = argResult {
                            switch argResult {
                            case .variable(let node):
                                closedLet[name] = node
                            case .number(let node):
                                closedLet[name] = node
                            case .function(let node, _):
                                closedLet[name] = node
                            case .unknown(let node):
                                closedLet[name] = node
                            }
                        } else {
                            return argResult
                        }
                    }
                    let args = function.prototype.argumentNames[item.arguments.count...]
                    let thunk = FunctionNode(prototype: PrototypeNode(name: VariableNode(name: anonName(), subscripts: [], startToken: function.startToken),
                                                                      argumentNames: Array(args),
                                                                      startToken: function.startToken),
                                             body: function.body,
                                             closed: closedLet,
                                             startToken: item.startToken)
                    return .success(.function(node: thunk, arguments: thunk.prototype.argumentNames.count))
                }
            }
        default:
            return .failure(.UnhandledExpression(token: item.startToken))

        }
    }
}
