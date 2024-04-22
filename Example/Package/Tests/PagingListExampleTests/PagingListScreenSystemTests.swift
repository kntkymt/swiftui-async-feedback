import XCTest
@testable import PagingListExample
import AsyncFeedback
import AsyncFeedbackTestSupport
import SwiftUI

extension API {
    static func stub(responses: [Result<[Post], any Error>]) -> API {
        var responses = responses
        return API { _, _ in
            try responses.removeFirst().get()
        }
    }
}

enum TestAPIError: Error {
    case network
}

final class PagingScreenSystemTests: XCTestCase {

    @MainActor
    func testLoadings() async {

        let post0 = Post(id: 0, title: "post0")
        let post1 = Post(id: 1, title: "post1")
        let post2 = Post(id: 2, title: "post2")
        let responses: [Result<[Post], any Error>] = [
            .success([post0]),
            .success([post1]),
            .failure(TestAPIError.network),
            .success([post2])
        ]
        let dependency = PagingListScreenSystem.Dependency(api: .stub(responses: responses))
        let context = TestContext(
            state: PagingListScreenSystem.State(),
            system: PagingListScreenSystem(dependency: dependency)
        )

        await context
            .check { state in
                XCTAssertTrue(state.postStatus.isIdle)
            }
            .run()
            .send(.load)
            .suspend(while: \.postStatus.isLoading)
            .check { state in
                XCTAssertTrue(state.postStatus.isSuccess)
                XCTAssertEqual(state.postStatus.value, [post0])
            }
            .send(.loadMore)
            .suspend(while: \.postStatus.isPaging)
            .check { state in
                XCTAssertTrue(state.postStatus.isSuccess)
                XCTAssertEqual(state.postStatus.value, [post0, post1])
            }
            .send(.loadMore)
            .suspend(while: \.postStatus.isPaging)
            .check { state in
                XCTAssertTrue(state.postStatus.isPagingFailure)

                XCTAssertEqual(state.postStatus.value, [post0, post1])
            }
            .send(.loadMore)
            .suspend(while: \.postStatus.isPaging)
            .check { state in
                XCTAssertTrue(state.postStatus.isSuccess)

                XCTAssertEqual(state.postStatus.value, [post0, post1, post2])
            }
            .finish()
    }
}
