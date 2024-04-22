import SwiftUI
import AsyncFeedback

struct Todo: Identifiable, Equatable {
    var id: Int

    var title: String
    var isCompleted: Bool

    init(id: Int, title: String, isCompleted: Bool) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
    }
}

enum Filter: CaseIterable, Hashable {
    case all
    case completed
    case notCompleted
}

private extension Filter {
    var title: String {
        switch self {
        case .all: "All"
        case .completed: "Completed"
        case .notCompleted: "Not Completed"
        }
    }
}

struct TodoScreenSystem: SystemProtocol {
    struct State {
        var todoInputText: String = ""
        var todos: [Todo] = []
        var isAddingTodo: Bool = false

        var filter: Filter = .all

        var isAddButtonDisabled: Bool = false
    }

    enum Event {
        case addingTodo
        case addedTodo(Todo)
        case setIsComplete(todoId: Todo.ID, isCompleted: Bool)

        case setIsAddButtonDisabled(Bool)
    }

    func reducer() -> Reducer {
        { state, event in
            switch event {
            case .addingTodo:
                state.isAddingTodo = true

            case .addedTodo(let todo):
                state.isAddingTodo = false
                state.todos.append(todo)
                state.todoInputText = ""

            case .setIsComplete(let id, let isCompleted):
                guard let index = state.todos.firstIndex(where: { $0.id == id }) else { return }
                state.todos[index].isCompleted = isCompleted

            case .setIsAddButtonDisabled(let disabled):
                state.isAddButtonDisabled = disabled
            }
        }
    }

    func feedbacks() -> [Feedback<Self>] {
        [
            .loadInitialTodo(),
            .addTodo(),
            .validateInputText()
        ]
    }
}

extension TodoScreenSystem.State {
    var filteredTodos: [Todo] {
        switch filter {
        case .all: todos
        case .completed: todos.filter(\.isCompleted)
        case .notCompleted: todos.filter { !$0.isCompleted }
        }
    }
}

struct TodoScreen: View {

    @ViewContext(state: TodoScreenSystem.State(), system: TodoScreenSystem())
    var context

    var body: some View {
        List {
            filterSegmentSection

            todosSection

            inputTodoSection
        }
        .task {
            await _context.runFeedbackLoop()
        }
        .animation(.default, value: context.todos)
        .animation(.default, value: context.filter)
        .navigationTitle("Todo")
    }
}

extension TodoScreen {
    var filterSegmentSection: some View {
        Section {
            Picker("Filter", selection: $context.filter) {
                ForEach(Filter.allCases, id: \.self) { filter in
                    Text(filter.title)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    var todosSection: some View {
        Section {
            let filteredTodo = context.filteredTodos
            if filteredTodo.isEmpty {
                Text("No Todos")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            } else {
                ForEach(filteredTodo) { todo in
                    HStack {
                        Toggle(isOn: Binding(get: {
                            todo.isCompleted
                        }, set: { newValue in
                            _context.send(.setIsComplete(todoId: todo.id, isCompleted: newValue))
                        })) {
                            Text(todo.title)
                        }
                    }
                }
            }
        }
    }

    var inputTodoSection: some View {
        Section {
            TextField("TextField", text: $context.todoInputText, prompt: Text("Make lunch"))
                .frame(maxWidth: .infinity)

            Button {
                _context.send(.addingTodo)
            } label: {
                Text("Add")
                    .frame(maxWidth: .infinity)
            }
            .disabled(context.isAddButtonDisabled)
        }
    }
}
