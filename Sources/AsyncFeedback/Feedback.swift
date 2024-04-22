public struct Feedback<System: SystemProtocol>: Sendable {

    // MARK: - Property

    public let react: React
    public let evaluate: @Sendable (System.State) async -> System.Event?

    // MARK: - Initializer

    public init(_ react: React, evaluate: @Sendable @escaping (System.State) async -> System.Event?) {
        self.react = react
        self.evaluate = evaluate
    }
}

extension Feedback {
    public struct React: Sendable {

        // MARK: - Property

        public let evaluate: @Sendable (_ previousState: System.State?, _ newState: System.State) -> Bool

        // MARK: - Initializer

        private init(evaluate: @Sendable @escaping (_: System.State?, _: System.State) -> Bool) {
            self.evaluate = evaluate
        }

        // MARK: - Public

        public static var once: Self {
            React { previousState, _ in
                previousState == nil
            }
        }

        public static func onChanged<T: Equatable>(_ keypath: KeyPath<System.State, T>) -> Self {
            React { previous, new in
                previous?[keyPath: keypath] != new[keyPath: keypath]
            }
        }

        public static func filter(_ condition: @Sendable @escaping (System.State) -> Bool) -> Self {
            React { _, new in
                condition(new)
            }
        }
    }
}

extension KeyPath: @unchecked Sendable {}
