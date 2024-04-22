import SwiftUI
import CounterExample
import TodoExample
import PagingListExample

public struct ExampleApp: App {
    public init() {}

    public var body: some Scene {
        WindowGroup {
            NavigationStack {
                List {
                    NavigationLink("Counter", destination: CounterExampleApp())

                    NavigationLink("Todo", destination: TodoExampleApp())

                    NavigationLink("Paging", destination: PagingListExampleApp())
                }
                .navigationTitle("Examples")
            }
        }
    }
}
