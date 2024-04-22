import AsyncFeedback

actor AtomicArray<T> {
    var value: [T]

    init(_ value: [T]) {
        self.value = value
    }

    func append(_ newElement: T) {
        value.append(newElement)
    }
}

struct TestSystem: SystemProtocol {
    struct State: Equatable {
        var count: Int = 0
        var message: String = ""
    }

    enum Event: Equatable {
        case setCount(Int)
        case setMessage(String)
    }

    let reducerCall = AtomicArray<(State, Event)>([])
    let feedbackCall1 = AtomicArray<State>([])
    let feedbackCall2 = AtomicArray<State>([])

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
            Feedback(.filter { _ in true }) { state in
                await feedbackCall1.append(state)

                return nil
            },
            Feedback(.filter { _ in true }) { state in
                await feedbackCall2.append(state)

                return nil
            }
        ]
    }
}
