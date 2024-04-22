import XCTest
@testable import CounterExample
import AsyncFeedback
import AsyncFeedbackTestSupport
import SwiftUI

final class CounterScreenSystemTests: XCTestCase {

    @MainActor
    func testWhenCountIsMultipleOf3() async {
        let context = TestContext(
            state: CounterScreenSystem.State(),
            system: CounterScreenSystem()
        )

        await context
            .check { state in
                XCTAssertEqual(state.count, 1)
                XCTAssertNil(state.message)
            }
            .run()
            .do {
                context.eventBinding.count.wrappedValue = 3
            }
            .suspend(while: context.state.message == nil)
            .check { state in
                XCTAssertEqual(state.message, "multiple of 3!!")
            }
            .finish()
    }
}
