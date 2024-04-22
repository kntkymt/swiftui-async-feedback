import AsyncFeedback
import Foundation

extension Feedback where System == TodoScreenSystem {
    static func validateInputText() -> Self {
        Feedback(.onChanged(\.todoInputText)) { state in
            if state.todoInputText.isEmpty {
                return .setIsAddButtonDisabled(true)
            }

            if state.todoInputText.count > 10 {
                return .setIsAddButtonDisabled(true)
            }

            return .setIsAddButtonDisabled(false)
        }
    }
}
