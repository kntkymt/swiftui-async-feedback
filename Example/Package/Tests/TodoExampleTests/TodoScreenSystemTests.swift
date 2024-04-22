import XCTest
@testable import TodoExample
import AsyncFeedback
import AsyncFeedbackTestSupport
import SwiftUI

final class TodoScreenSystemTests: XCTestCase {

    @MainActor
    func testAddTodoAndFilter() async {
        let context = TestContext(
            state: TodoScreenSystem.State(),
            system: TodoScreenSystem()
        )

        await context
            .check { state in
                XCTAssertEqual(state.filter, .all)
                XCTAssertEqual(state.todos, [])
                XCTAssertFalse(state.isAddButtonDisabled)
                XCTAssertFalse(state.isAddingTodo)
            }
            .run()
            .suspend(while: \.todos.isEmpty)
            .check { state in
                XCTAssertEqual(state.todos, [Todo(id: 0, title: "Wake up", isCompleted: false)])
            }
            .do {
                context.eventBinding.todoInputText.wrappedValue = "Make lunch"
            }
            .send(.addingTodo)
            .suspend(while: \.isAddingTodo)
            .check { state in
                let todos = [
                    Todo(id: 0, title: "Wake up", isCompleted: false),
                    Todo(id: 1, title: "Make lunch", isCompleted: false)
                ]
                XCTAssertEqual(state.todos, todos)

                XCTAssertEqual(state.todoInputText, "")

                XCTAssertEqual(state.filter, .all)
                XCTAssertEqual(state.filteredTodos, todos)
            }
            .send(.setIsComplete(todoId: 0, isCompleted: true))
            .check { state in
                let todos = [
                    Todo(id: 0, title: "Wake up", isCompleted: true),
                    Todo(id: 1, title: "Make lunch", isCompleted: false)
                ]
                XCTAssertEqual(state.todos, todos)
            }
            .do {
                context.eventBinding.filter.wrappedValue = .notCompleted
            }
            .check { state in
                let todos = [
                    Todo(id: 1, title: "Make lunch", isCompleted: false)
                ]
                XCTAssertEqual(state.filteredTodos, todos)
            }
            .do {
                context.eventBinding.filter.wrappedValue = .completed
            }
            .check { state in
                let todos = [
                    Todo(id: 0, title: "Wake up", isCompleted: true)
                ]
                XCTAssertEqual(state.filteredTodos, todos)
            }
            .finish()
    }

    @MainActor
    func testInputValidation() async {
        let context = TestContext(
            state: TodoScreenSystem.State(),
            system: TodoScreenSystem()
        )

        await context
            .check { state in
                XCTAssertFalse(state.isAddButtonDisabled)
            }
            .run()
            .suspend(while: !context.state.isAddButtonDisabled)
            .check { state in
                XCTAssertTrue(state.isAddButtonDisabled)
            }
            .do {
                context.eventBinding.todoInputText.wrappedValue = "Make"
            }
            .suspend(while: context.state.isAddButtonDisabled)
            .check { state in
                XCTAssertFalse(state.isAddButtonDisabled)
            }
            .do {
                context.eventBinding.todoInputText.wrappedValue = "Make Lunch!!!"
            }
            .suspend(while: !context.state.isAddButtonDisabled)
            .check { state in
                XCTAssertTrue(state.isAddButtonDisabled)
            }
            .finish()
    }
}
