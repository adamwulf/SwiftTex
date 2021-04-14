import XCTest
@testable import SwiftTex

final class SwiftTexTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(SwiftTex().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
