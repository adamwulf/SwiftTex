//
//  File.swift
//  
//
//  Created by Adam Wulf on 10/27/21.
//

import Foundation

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

    mutating func set(_ variable: VariableNode, to expr: ExprNode) {
        if var last = scopes.last {
            last[variable] = expr
            scopes.removeLast()
            scopes.append(last)
        } else {
            globalScope[variable] = expr
        }
    }
}

struct TypeEnvironment {
    private var globalScope: [VariableNode: TypeChecker.ValueType] = [:]

    private var scopes: [[VariableNode: TypeChecker.ValueType]] = []

    private var currentScope: [VariableNode: TypeChecker.ValueType] {
        return scopes.last ?? globalScope
    }

    var environment: [VariableNode: TypeChecker.ValueType] {
        let allScopes = [globalScope] + scopes
        var ret: [VariableNode: TypeChecker.ValueType] = [:]
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
        environment.reduce("") { (partialResult: String, pair: (key: VariableNode, value: TypeChecker.ValueType)) -> String in
            return partialResult + (partialResult.isEmpty ? "" : "\n") + pair.key.asTex + " => " + pair.value.description
        }
    }

    mutating func pushScope() {
        scopes.append([:])
    }

    mutating func popScope() {
        scopes.removeLast()
    }

    func lookup(variable: VariableNode) -> TypeChecker.ValueType? {
        for scope in ([globalScope] + scopes).reversed() {
            for (scoped, val) in scope {
                if scoped.matches(variable) {
                    return val
                }
            }
        }
        return nil
    }

    mutating func set(_ variable: VariableNode, to expr: TypeChecker.ValueType) {
        if var last = scopes.last {
            last[variable] = expr
            scopes.removeLast()
            scopes.append(last)
        } else {
            globalScope[variable] = expr
        }
    }
}
