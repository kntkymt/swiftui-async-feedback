import XCTest
@testable import AsyncFeedback

final class FeedbackReactTests: XCTestCase {
    func testOnce() {
        let react = Feedback<TestSystem>.React.once

        XCTAssertTrue(react.evaluate(nil, TestSystem.State(count: 0)))
        XCTAssertFalse(react.evaluate(TestSystem.State(count: 0), TestSystem.State(count: 0)))
        XCTAssertFalse(react.evaluate(TestSystem.State(count: 0), TestSystem.State(count: 1)))
    }

    func testOnChanged() {
        let react = Feedback<TestSystem>.React.onChanged(\.count)

        XCTAssertTrue(react.evaluate(nil, TestSystem.State(count: 0)))
        XCTAssertFalse(react.evaluate(TestSystem.State(count: 0, message: ""), TestSystem.State(count: 0, message: "")))
        XCTAssertFalse(react.evaluate(TestSystem.State(count: 0, message: ""), TestSystem.State(count: 0, message: "aaaa")))
        XCTAssertTrue(react.evaluate(TestSystem.State(count: 0, message: ""), TestSystem.State(count: 1, message: "")))
    }

    func testFilter() {
        let react = Feedback<TestSystem>.React.filter { $0.count == 10 }

        XCTAssertFalse(react.evaluate(nil, TestSystem.State(count: 0)))
        XCTAssertTrue(react.evaluate(nil, TestSystem.State(count: 10)))
        XCTAssertFalse(react.evaluate(TestSystem.State(count: 10, message: ""), TestSystem.State(count: 0, message: "10")))
        XCTAssertTrue(react.evaluate(TestSystem.State(count: 0, message: ""), TestSystem.State(count: 10, message: "10")))
    }
}
