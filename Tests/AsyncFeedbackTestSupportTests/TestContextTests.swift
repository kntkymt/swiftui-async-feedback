import XCTest
import AsyncFeedback
@testable import AsyncFeedbackTestSupport

struct TestSystem: SystemProtocol {
    struct State {
        var count = 0
        var bool = false
    }

    enum Event {
    }

    func reducer() -> Reducer {
        { state, event in

        }
    }

    func feedbacks() -> [Feedback<Self>] {
        []
    }
}

final class TestContextTests: XCTestCase {
    // FIXME: Should we test run, send, eventBinding by making Context injectable?
    @MainActor
    func testCheck() async {
        let context = TestContext(state: .init(count: 0), system: TestSystem())

        context.state.count = 1

        await context
            .check { state in
                XCTAssertEqual(state.count, 1)
            }
            .do {
                context.state.count += 1
            }
            .check { state in
                XCTAssertEqual(state.count, 2)
            }
            .finish()
    }

    @MainActor
    func testBinding() async {
        let context = TestContext(state: .init(count: 0), system: TestSystem())

        context.state.count = 1
        let binding = context.binding

        XCTAssertEqual(context.state.count, binding.count.wrappedValue)

        binding.count.wrappedValue = 10

        XCTAssertEqual(context.state.count, binding.count.wrappedValue)

        binding.wrappedValue = .init(count: 1111, bool: false)

        XCTAssertEqual(context.state.count, binding.count.wrappedValue)
    }

    @MainActor
    func testSuspendValue() async {
        let context = TestContext(state: .init(count: 0), system: TestSystem())

        let expect = expectation(description: "suspend")
        var count = 0

        Task {
            await context
                .suspend(while: count != 5)
                .finish()

            XCTAssertEqual(count, 5)

            expect.fulfill()
        }

        for _ in 0..<10 {
            count += 1
            await Task.yield()
        }

        await fulfillment(of: [expect], timeout: 10)
    }

    @MainActor
    func testSuspendState() async {
        let context = TestContext(state: .init(count: 0, bool: true), system: TestSystem())

        let expect = expectation(description: "suspend")

        XCTAssertTrue(context.state.bool)

        Task {
            await context
                .suspend(while: \.bool)
                .finish()

            XCTAssertFalse(context.state.bool)

            expect.fulfill()
        }

        for _ in 0..<10 {
            context.state.bool.toggle()
            await Task.yield()
        }

        await fulfillment(of: [expect], timeout: 10)
    }
}
