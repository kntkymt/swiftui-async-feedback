import AsyncFeedback
import Foundation

extension Feedback where System == TodoScreenSystem {
    static func loadInitialTodo() -> Self {
        Feedback(.once) { _ in
            let sampleTodo = Todo(id: 0, title: "Wake up", isCompleted: false)
            return .addedTodo(sampleTodo)
        }
    }
}
