import AsyncFeedback
import SwiftUI

struct CounterScreenSystem: SystemProtocol {
    struct State {
        var count: Int = 1
        var message: String? = nil
    }

    enum Event {
        case setMessage(String?)
    }

    func reducer() -> Reducer {
        { state, event in
            switch event {
            case .setMessage(let message):
                state.message = message
            }
        }
    }

    func feedbacks() -> [Feedback<Self>] {
        [
            Feedback(.onChanged(\.count)) { state in
                if state.count.isMultiple(of: 3) {
                    return .setMessage("multiple of 3!!")
                } else {
                    return .setMessage(nil)
                }
            }
        ]
    }
}

struct CounterScreen: View {

    @ViewContext(state: CounterScreenSystem.State(), system: CounterScreenSystem())
    var context

    var body: some View {
        VStack {
            Text(context.count.description)
                .font(.largeTitle)

            Stepper("", value: $context.count)
                .labelsHidden()

            Text(context.message ?? "")
                .foregroundStyle(.red)
                .font(.largeTitle)
                .frame(height: 30)
        }
        .task {
            await _context.runFeedbackLoop()
        }
        .navigationTitle("Counter")
    }
}
