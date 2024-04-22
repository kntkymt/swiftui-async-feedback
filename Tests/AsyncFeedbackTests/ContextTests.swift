import XCTest
import SwiftUI
@testable import AsyncFeedback

final class ContextTests: XCTestCase {

    @MainActor
    func testFeedbackReactToInitialState() async {
        let system = TestSystem()
        let context = Context(system: system)

        let initialState = TestSystem.State(count: 0, message: "")
        var state = initialState
        let binding = Binding {
            state
        } set: { newValue in
            state = newValue
        }

        let task = Task {
            await context.runFeedbackLoop(state: binding)
        }

        for _ in 0..<100 {
            await Task.yield()
        }

        let f1 = await system.feedbackCall1.value
        let f2 = await system.feedbackCall2.value
        let r = await system.reducerCall.value

        // Feedbacks will be parallelly executed, not serially
        //
        // parallelly:
        // let events = [feedback1(state), feedback2(state)]
        // for event in events { reducer(&state, event) }
        //
        // serially:
        // let event1 = feedback1(state)
        // let state1 = reducer(state, event1)
        // let event2 = feedback2(state1)
        // let state2 = reducer(state1, event2)
        XCTAssertEqual(f1, [initialState])
        XCTAssertEqual(f2, [initialState])


        XCTAssertTrue(r.isEmpty)

        task.cancel()
    }

    @MainActor
    func testContextDoNothingUntilRunFeedbackLoop() async throws {
        let system = TestSystem()
        let context = Context(system: system)

        let event = TestSystem.Event.setCount(10)
        Task {
            await context.send(event).value
        }

        for _ in 0..<100 {
            await Task.yield()
        }

        do {
            let f1 = await system.feedbackCall1.value
            let f2 = await system.feedbackCall2.value
            let r = await system.reducerCall.value

            XCTAssertTrue(f1.isEmpty)
            XCTAssertTrue(f2.isEmpty)
            XCTAssertTrue(r.isEmpty)
        }

        let initialState = TestSystem.State(count: 0, message: "")
        var state = initialState
        let binding = Binding {
            state
        } set: { newValue in
            state = newValue
        }

        // if `runFeedbackLoop()` after sending an event, the event will trriger reducer because event is queued and holded by context.
        let task = Task {
            await context.runFeedbackLoop(state: binding)
        }

        for _ in 0..<100 {
            await Task.yield()
        }

        do {
            let f1 = await system.feedbackCall1.value
            let f2 = await system.feedbackCall2.value
            let r = await system.reducerCall.value

            // initialState + chenged state by reducer via manualEvent
            XCTAssertEqual(f1, [initialState, TestSystem.State(count: 10, message: "")])
            XCTAssertEqual(f2, [initialState, TestSystem.State(count: 10, message: "")])


            XCTAssertEqual(r.count, 1)

            let (s, e) = try XCTUnwrap(r.first)

            XCTAssertEqual(s, initialState)
            XCTAssertEqual(e, event)
        }

        task.cancel()
    }

    @MainActor
    func testContextCancelAndRunAgain() async {
        let system = TestSystem()
        let context = Context(system: system)

        let initialState = TestSystem.State(count: 0, message: "")
        var state = initialState
        let binding = Binding {
            state
        } set: { newValue in
            state = newValue
        }

        let task1 = Task {
            await context.runFeedbackLoop(state: binding)
        }

        for _ in 0..<100 {
            await Task.yield()
        }

        do {
            let f1 = await system.feedbackCall1.value
            let f2 = await system.feedbackCall2.value
            let r = await system.reducerCall.value


            XCTAssertEqual(f1, [initialState])
            XCTAssertEqual(f2, [initialState])
            XCTAssertTrue(r.isEmpty)
        }

        task1.cancel()

        let task2 = Task {
            await context.runFeedbackLoop(state: binding)
        }

        for _ in 0..<100 {
            await Task.yield()
        }

        do {
            // if run context again after canceled at once, context will not send iniatialState.
            let f1 = await system.feedbackCall1.value
            let f2 = await system.feedbackCall2.value
            let r = await system.reducerCall.value


            XCTAssertEqual(f1, [initialState])
            XCTAssertEqual(f2, [initialState])
            XCTAssertTrue(r.isEmpty)
        }

        task2.cancel()
    }

    // sometimes usefull but maybe harmful feature.
    // this feature may be removed in future.
    @MainActor
    func testEventBinding() async {
        let system = TestSystem()
        let context = Context(system: system)

        let initialState = TestSystem.State(count: 0, message: "")
        var state = initialState
        let binding = Binding {
            state
        } set: { newValue in
            state = newValue
        }

        let task = Task {
            await context.runFeedbackLoop(state: binding)
        }
        for _ in 0..<100 {
            await Task.yield()
        }

        let eventBinding = context.binding(base: binding)
        eventBinding.wrappedValue.count = 10

        for _ in 0..<100 {
            await Task.yield()
        }

        do {
            let f1 = await system.feedbackCall1.value
            let f2 = await system.feedbackCall2.value
            let r = await system.reducerCall.value

            XCTAssertEqual(f1, [initialState, TestSystem.State(count: 10, message: "")])
            XCTAssertEqual(f2, [initialState, TestSystem.State(count: 10, message: "")])
            XCTAssertTrue(r.isEmpty)
        }

        task.cancel()
    }

    @MainActor
    func testSendSuspendingWhile() async {
        let system = TestSystem()
        let context = Context(system: system)

        let initialState = TestSystem.State(count: 0, message: "")
        var state = initialState
        let binding = Binding {
            state
        } set: { newValue in
            state = newValue
        }

        let task = Task {
            await context.runFeedbackLoop(state: binding)
        }

        await context.send(.setCount(10), suspendingWhile: state.count != 10)
        XCTAssertEqual(state.count, 10)

        task.cancel()
    }

    @MainActor
    func testFeedbackChain() async {
        let system = TestFeedbackSystem()
        let context = Context(system: system)

        let initialState = TestFeedbackSystem.State(count: 0, message: "")
        var state = initialState
        let binding = Binding {
            state
        } set: { newValue in
            state = newValue
        }

        let task = Task {
            await context.runFeedbackLoop(state: binding)
        }

        for _ in 0..<100 {
            await Task.yield()
        }

        do {
            let f1 = await system.feedbackCall1.value
            let f2 = await system.feedbackCall2.value
            let f3 = await system.feedbackCall3.value
            let r = await system.reducerCall.value

            XCTAssertEqual(f1, [initialState])
            XCTAssertEqual(f2, [TestFeedbackSystem.State(count: 10, message: "")])
            XCTAssertEqual(f3, [TestFeedbackSystem.State(count: 10, message: "Hello")])

            XCTAssertEqual(r.count, 2)

            let (s0, e0) = r[0]
            XCTAssertEqual(s0, initialState)
            XCTAssertEqual(e0, .setCount(10))

            let (s1, e1) = r[1]
            XCTAssertEqual(s1, TestFeedbackSystem.State(count: 10, message: ""))
            XCTAssertEqual(e1, .setMessage("Hello"))
        }

        task.cancel()
    }
}
