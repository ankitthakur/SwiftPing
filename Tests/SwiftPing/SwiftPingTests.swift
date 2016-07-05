import XCTest
@testable import SwiftPing

class SwiftPingTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(SwiftPing().text, "Hello, World!")
    }


    static var allTests : [(String, (SwiftPingTests) -> () throws -> Void)] {
        return [
            ("testExample", testExample),
        ]
    }
}
