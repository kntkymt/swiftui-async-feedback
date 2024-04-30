import XCTest
import AsyncFeedback
@testable import AsyncFeedbackTestSupport

final class TestClockTests: XCTestCase {

    @MainActor
    func testSchedule() async throws {
        let clock = TestClock(initialInstant: .zero)

        var count = 0

        // schedule
        // id   : A B B C C
        // clock: 0 1 2 3 4 5
        // count: 0 1 1 3 3 6
        let task = Task {
            // clock: 0
            try await clock.sleep(id: "A", for: .seconds(1))

            count += 1

            // clock: 1, 2
            try await clock.sleep(id: "B", for: .seconds(2))

            count += 2

            // clock: 3, 4
            try await clock.sleep(id: "C", until: .init(offset: .seconds(5)))

            // clock: 5
            count += 3
        }

        //        ↓
        // id   : A B B C C
        // clock: 0 1 2 3 4 5
        // count: 0 1 1 3 3 6
        try await clock.sleep(untilSuspendBy: "A")
        XCTAssertEqual(count, 0)

        clock.advance(by: .seconds(1))

        //          ↓
        // id   : A B B C C
        // clock: 0 1 2 3 4 5
        // count: 0 1 1 3 3 6
        try await clock.sleep(untilSuspendBy: "B")
        XCTAssertEqual(count, 1)

        clock.advance(by: .seconds(1))

        //            ↓
        // id   : A B B C C
        // clock: 0 1 2 3 4 5
        // count: 0 1 1 3 3 6
        try await clock.sleep(untilSuspendBy: "B")
        XCTAssertEqual(count, 1)

        clock.advance(by: .seconds(1))

        //              ↓
        // id   : A B B C C
        // clock: 0 1 2 3 4 5
        // count: 0 1 1 3 3 6
        try await clock.sleep(untilSuspendBy: "C")
        XCTAssertEqual(count, 3)

        clock.advance(by: .seconds(3))

        //                    ↓
        // id   : A B B C C
        // clock: 0 1 2 3 4 5 6
        // count: 0 1 1 3 3 6 6
        try await task.value
        XCTAssertEqual(count, 6)
    }

    @MainActor
    func testResumeImmediate() async throws {
        let clock = TestClock(initialInstant: .zero)

        var count = 0
        //            ↓
        // clock: 0 1 2
        // count: 0 0 0
        clock.advance(by: .seconds(2))

        // schedule
        // id   :   A B C
        // clock: 0 1 2 3
        // count: 0 1 3 6
        let task = Task {
            // clock: 0
            try await clock.sleep(id: "A", until: .init(offset: .seconds(1)))

            // clock: 1
            count += 1
            try await clock.sleep(id: "B", until: .init(offset: .seconds(2)))

            // clock: 2
            count += 2
            try await clock.sleep(id: "C", until: .init(offset: .seconds(3)))

            // clock: 3
            count += 3
        }

        //            ↓
        // id   : A B C
        // clock: 0 1 2 3
        // count: 0 0 3 6
        try await clock.sleep(untilSuspendBy: "C")
        XCTAssertEqual(count, 3)

        clock.advance(by: .seconds(1))

        //              ↓
        // id   : A B C
        // clock: 0 1 2 3
        // count: 0 1 3 6
        try await task.value
        XCTAssertEqual(count, 6)
    }

    @MainActor
    func testCancel() async throws {
        let clock = TestClock(initialInstant: .zero)

        var count = 0

        // schedule
        // id   : A
        // clock: 0 1
        // count: 0 1
        let task = Task {
            // clock: 0
            try await clock.sleep(id: "A", until: .init(offset: .seconds(1)))
            count += 1
        }

        try await clock.sleep(untilSuspendBy: "A")
        task.cancel()
        clock.advance(by: .seconds(1))

        do {
            try await task.value
        } catch is CancellationError {
            XCTAssertEqual(count, 0)
        } catch {
            XCTFail()
        }
    }

    @MainActor
    func testCancelImmediate() async throws {
        let clock = TestClock(initialInstant: .zero)

        var count = 0

        // schedule
        // id   : A
        // clock: 0 1
        // count: 0 1
        let task = Task {
            // clock: 0
            try await clock.sleep(id: "A", until: .init(offset: .seconds(1)))
            count += 1
        }

        task.cancel()

        do {
            try await task.value
        } catch is CancellationError {
            XCTAssertEqual(count, 0)
        } catch {
            XCTFail()
        }
    }
}
