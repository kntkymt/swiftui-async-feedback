import SwiftUI

@MainActor
@propertyWrapper
public struct ViewContext<System: SystemProtocol>: DynamicProperty {

    // MARK: - Property

    @State private var state: System.State
    @StateObject private var context: Context<System>

    public var wrappedValue: System.State {
        state
    }

    public var projectedValue: Binding<System.State> {
        context.binding(base: $state)
    }

    // MARK: - Initializer

    public init(state: System.State, system: System) {
        self._state = State(initialValue: state)
        self._context = StateObject(wrappedValue: Context(system: system))
    }

    // MARK: - Property

    public func runFeedbackLoop() async {
        await context.runFeedbackLoop(state: $state)
    }

    @discardableResult
    public func send(_ event: System.Event) -> Task<Void, Never> {
        context.send(event)
    }

    public func send(_ event: System.Event, suspendingWhile value: @autoclosure @escaping () -> Bool) async {
        await context.send(event, suspendingWhile: value())
    }
}
