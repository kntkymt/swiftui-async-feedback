import SwiftUI

struct ErrorStateView: View {

    // MARK: - Property

    let action: (() -> Void)?

    // MARK: - Initializer

    init(action: (() -> Void)? = nil) {
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        VStack {
            Text("Error occured")
                .fontWeight(.medium)
                .font(.title3)

            if let action {
                Text("Reload")
                    .font(.title3)
                    .foregroundColor(Color(.link))
                    .onTapGesture {
                        action()
                    }
            }
        }
    }
}
