import AsyncFeedback
import AsyncFeedbackTestSupport

struct TestFeedbackSystem: SystemProtocol {
    struct State: Equatable {
        var count: Int = 0
        var message: String = ""
    }

    enum Event: Equatable {
        case setCount(Int)
        case setMessage(String)
    }

    let clock = TestClock(initialInstant: .zero)
    let reducerCall = AtomicArray<(State, Event)>([])
    let feedbackCall1 = AtomicArray<State>([])
    let feedbackCall2 = AtomicArray<State>([])
    let feedbackCall3 = AtomicArray<State>([])

    func reducer() -> Reducer {
        { state, event in
            let letState = state
            Task {
                await reducerCall.append((letState, event))
            }

            switch event {
            case .setCount(let count):
                state.count = count

            case .setMessage(let message):
                state.message = message
            }
        }
    }

    func feedbacks() -> [Feedback<Self>] {
        [
            Feedback(.once) { state in
                await feedbackCall1.append(state)
                try? await clock.sleep(for: .seconds(1))

                return .setCount(10)
            },
            Feedback(.onChanged(\.count)) { state in
                guard state.count == 10 else { return nil }
                await feedbackCall2.append(state)
                try? await clock.sleep(for: .seconds(1))

                return .setMessage("Hello")
            },
            Feedback(.onChanged(\.message)) { state in
                guard state.message == "Hello" else { return nil }
                await feedbackCall3.append(state)
                try? await clock.sleep(for: .seconds(1))

                return nil
            }
        ]
    }
}
