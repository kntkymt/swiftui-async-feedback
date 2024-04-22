import AsyncFeedback
import Foundation

extension Feedback where System == TodoScreenSystem {
    static func addTodo() -> Self {
        Feedback(.onChanged(\.isAddingTodo)) { state in
            guard state.isAddingTodo else { return nil }

            let todo = Todo(id: state.todos.count, title: state.todoInputText, isCompleted: false)
            return .addedTodo(todo)
        }
    }
}
