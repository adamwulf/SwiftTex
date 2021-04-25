//
//  File.swift
//  
//
//  Created by Adam Wulf on 4/25/21.
//

import Foundation

extension String {
    func countOccurrences<Target>(of string: Target) -> Int where Target: StringProtocol {
        return components(separatedBy: string).count - 1
    }

    func countOccurrences(of chars: CharacterSet) -> Int {
        return components(separatedBy: chars).count - 1
    }
}
