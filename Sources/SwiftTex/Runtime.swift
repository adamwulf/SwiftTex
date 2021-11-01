//
//  Runtime.swift
//  
//
//  Created by Adam Wulf on 10/31/21.
//

import Foundation

class Runtime {
    typealias Success = (parsed: ExprNode, evaluated: ExprNode)
    typealias Failure = Error

    static func run(source: String) -> [Result<Success, Failure>] {
        let lexer = Lexer(input: source)
        let (tokens, _) = lexer.tokenize()
        let interpreter = Interpreter()
        let parser = Parser(tokens: tokens, currentEnvironment: { interpreter.env })
        let typeChecker = TypeChecker()
        var results: [Result<Success, Failure>] = []

        while true {
            do {
                guard let line = try parser.parseTopLevelExpression() else { break }
                let checked = typeChecker.visit(line)
                switch checked {
                case .failure(let error):
                    throw error
                case .success:
                    let eval = line.accept(visitor: interpreter)
                    switch eval {
                    case .failure(let error):
                        throw error
                    case .success(let evaluated):
                        let result: Success = (parsed: line, evaluated: evaluated)
                        results.append(.success(result))
                    }
                }
            } catch {
                results.append(.failure(error))
            }
        }

        return results
    }
}
