import AsyncFeedback
import SwiftUI

@MainActor
public class TestContext<System: SystemProtocol> {

    // MARK: - Property

    public var state: System.State
    public let context: Context<System>

    public var binding: Binding<System.State> {
        Binding {
            self.state
        } set: { newValue in
            self.state = newValue
        }

    }

    public var eventBinding: Binding<System.State> {
        context.binding(base: binding)
    }

    public var task: Task<Void, Never>?

    // MARK: - Initializer

    public init(state: System.State, system: System) {
        self.state = state
        self.context = Context(system: system)
    }

    // MARK: - Public

    public func run() -> Self {
        guard task == nil else { preconditionFailure("you must call finish() before call run() twice.") }

        task = Task {
            await context.runFeedbackLoop(state: binding)
        }

        return self
    }

    public func send(_ event: System.Event) async -> Self {
        await context.send(event).value

        return self
    }

    public func check(_ exec: (System.State) -> Void) async -> Self {
        for _ in 0..<5 {
            await Task.yield()
        }
        exec(state)

        return self
    }

    public func `do`(_ exec: () async -> Void) async -> Self {
        await exec()

        return self
    }

    public func suspend(while keypath: KeyPath<System.State, Bool>) async -> Self {
        await Task.yield()
        while state[keyPath: keypath] {
            await Task.yield()
        }

        return self
    }

    public func suspend(while value: @autoclosure () -> Bool) async -> Self {
        await Task.yield()
        while value() {
            await Task.yield()
        }

        return self
    }

    public func finish() {
        task?.cancel()
        task = nil
    }
}
