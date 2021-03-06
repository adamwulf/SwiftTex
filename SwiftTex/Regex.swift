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
    func match(regex: String, mustStart: Bool) -> (str: String, rng: NSRange)? {
        let expression: NSRegularExpression
        if let exists = expressions[regex] {
            expression = exists
        } else {
            expression = try! NSRegularExpression(pattern: mustStart ? "^\(regex)" : regex, options: [])
            expressions[regex] = expression
        }

        let range = expression.rangeOfFirstMatch(in: self, options: [], range: NSRange(location: 0, length: self.utf16.count))
        if range.location != NSNotFound {
            return ((self as NSString).substring(with: range), range)
        }
        return nil
    }
}
