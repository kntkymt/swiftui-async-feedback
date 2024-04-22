import AsyncAlgorithms
import SwiftUI

@MainActor
public final class Context<System: SystemProtocol>: ObservableObject {

    // MARK: - Property

    private let system: System
    private let manualEventChannel = AsyncChannel<System.Event>()
    private let stateChannel = AsyncChannel<(previousState: System.State?, newState: System.State)>()

    private var isFirstTime = true

    // MARK: - Initializer

    public init(system: System) {
        self.system = system
    }

    // MARK: - Public

    public func runFeedbackLoop(state: Binding<System.State>) async {
        if isFirstTime {
            Task {
                await stateChannel.send((nil, state.wrappedValue))
            }
            isFirstTime = false
        }

        let feedbackEventStream = stateChannel.flatMap { receivedState in
            AsyncStream { continuation in
                Task {
                    await withTaskGroup(of: Void.self) { taskGroup in
                        for feedback in self.system.feedbacks() {
                            let shouldEvaluate = feedback.react.evaluate(receivedState.previousState, receivedState.newState)

                            if shouldEvaluate {
                                taskGroup.addTask {
                                    if let event = await feedback.evaluate(receivedState.newState) {
                                        continuation.yield(event)
                                    }
                                }
                            }
                        }

                        await taskGroup.waitForAll()
                    }

                    continuation.finish()
                }
            }
        }

        let merged = merge(feedbackEventStream, manualEventChannel)
        do {
            for try await event in merged {
                let previousState = state.wrappedValue
                var newState = state.wrappedValue
                system.reducer()(&newState, event)

                state.wrappedValue = newState
                Task {
                    await stateChannel.send((previousState, newState))
                }
            }
        } catch {
            preconditionFailure("Why did the stream thorw even I didn't use ThrowingStream? Unreached?")
        }
    }

    public func binding(base: Binding<System.State>) -> Binding<System.State> {
        Binding {
            base.wrappedValue
        } set: { newState in
            let previousState = base.wrappedValue
            base.wrappedValue = newState

            Task {
                await self.stateChannel.send((previousState, newState))
            }
        }
    }

    @discardableResult
    nonisolated
    public func send(_ event: System.Event) -> Task<Void, Never> {
        Task {
            await manualEventChannel.send(event)
        }
    }

    public func send(_ event: System.Event, suspendingWhile value: @autoclosure @escaping () -> Bool) async {
        await send(event).value

        await Task.yield()
        while value() {
            await Task.yield()
        }
    }
}
