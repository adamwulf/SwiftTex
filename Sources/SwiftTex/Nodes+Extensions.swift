//
//  Nodes+Extensions.swift
//  SwiftTex
//
//  Created by Adam Wulf on 12/9/20.
//

import Foundation

extension NumberNode {
    static prefix func - (lhs: NumberNode) -> NumberNode {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = lhs.fractionalDigits
        let string = formatter.string(from: (-lhs.value) as NSNumber)!
        return NumberNode(string: string, startToken: lhs.startToken)
    }

    static func + (left: NumberNode, right: Float) -> NumberNode {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = left.fractionalDigits
        let string = formatter.string(from: (left.value + right) as NSNumber)!
        return NumberNode(string: string, startToken: left.startToken)
    }

    static func - (left: NumberNode, right: Float) -> NumberNode {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = left.fractionalDigits
        let string = formatter.string(from: (left.value - right) as NSNumber)!
        return NumberNode(string: string, startToken: left.startToken)
    }

    static func * (left: NumberNode, right: Float) -> NumberNode {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = left.fractionalDigits
        let string = formatter.string(from: (left.value * right) as NSNumber)!
        return NumberNode(string: string, startToken: left.startToken)
    }

    static func / (left: NumberNode, right: Float) -> NumberNode {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = left.fractionalDigits
        let string = formatter.string(from: (left.value / right) as NSNumber)!
        return NumberNode(string: string, startToken: left.startToken)
    }

    static func ^ (left: NumberNode, right: Float) -> NumberNode {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = left.fractionalDigits
        let string = formatter.string(from: pow(left.value, right) as NSNumber)!
        return NumberNode(string: string, startToken: left.startToken)
    }

    static func + (left: NumberNode, right: NumberNode) -> NumberNode {
        return left + right.value
    }

    static func - (left: NumberNode, right: NumberNode) -> NumberNode {
        return left - right.value
    }

    static func * (left: NumberNode, right: NumberNode) -> NumberNode {
        return left * right.value
    }

    static func / (left: NumberNode, right: NumberNode) -> NumberNode {
        return left / right.value
    }

    static func ^ (left: NumberNode, right: NumberNode) -> NumberNode {
        return left ^ right.value
    }
}
