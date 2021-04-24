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
    func match(regex: String, mustStart: Bool) -> (str: String, nsrange: NSRange, range: Range<String.Index>)? {
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
}
