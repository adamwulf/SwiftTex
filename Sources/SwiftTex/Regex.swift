//
//  Regex.swift
//  Kaleidoscope
//
//  Created by Matthew Cheok on 15/11/15.
//  Copyright © 2015 Matthew Cheok. All rights reserved.
//

import Foundation

var expressions = [String: NSRegularExpression]()
public extension String {
    typealias MatchResult = (str: String, nsrange: NSRange, range: Range<String.Index>)

    func match(regex: String, mustStart: Bool) -> MatchResult? {
        let expression: NSRegularExpression
        if let exists = expressions[regex] {
            expression = exists
        } else {
            expression = try! NSRegularExpression(pattern: mustStart ? "^\(regex)" : regex, options: [])
            expressions[regex] = expression
        }

        let nsrange = expression.rangeOfFirstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        if nsrange.location != NSNotFound,
           let range = Range(nsrange, in: self) {
            return ((self as NSString).substring(with: nsrange), nsrange, range)
        }
        return nil
    }

    func matches(regex: String, mustStart: Bool) -> [MatchResult] {
        var results: [MatchResult] = []
        let expression: NSRegularExpression
        if let exists = expressions[regex] {
            expression = exists
        } else {
            expression = try! NSRegularExpression(pattern: mustStart ? "^\(regex)" : regex, options: [])
            expressions[regex] = expression
        }

        let matches = expression.matches(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        for match in matches {
            if case let nsrange = match.range,
               nsrange.location != NSNotFound,
               let range = Range(nsrange, in: self) {
                results.append(((self as NSString).substring(with: nsrange), nsrange, range))
            }
        }
        return results
    }
}
