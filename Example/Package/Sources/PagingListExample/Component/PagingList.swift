import SwiftUI

struct PagingList<V: Collection, Content: View>: View where V: Sendable, V.Element: Sendable {

    // MARK: - Property

    private let dataState: PagingDataState<V, any Error>
    private let listContent: (V) -> Content
    private let onPaging: () -> Void

    // MARK: - Initializer

    init(
        dataState: PagingDataState<V, any Error>,
        listContent: @escaping (_ value: V) -> Content,
        onPaging: @escaping () -> Void
    ) {
        self.dataState = dataState
        self.listContent = listContent
        self.onPaging = onPaging
    }

    // MARK: - Body

    var body: some View {
        List {
            switch dataState {
            case .idle, .initialLoading:
                EmptyView()

            case .reLoading(let value),
                    .paging(let value),
                    .success(let value),
                    .pagingFailure(let value, _):
                if value.isEmpty {
                    Text("No Posts")
                        .font(.title3)
                        .fontWeight(.medium)
                } else {
                    listContent(value)

                    if dataState.isPagingFailure {
                        ErrorStateView {
                            onPaging()
                        }
                        .frame(height: 100)
                        .frame(maxWidth: .infinity)
                    } else {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .onAppear {
                                onPaging()
                            }
                    }
                }

            case .retryLoading,
                    .loadingFailure:
                ErrorStateView()
                    .frame(height: 300)
                    .frame(maxWidth: .infinity)
            }
        }
        .background(Color(.systemGroupedBackground))
        .overlay {
            if dataState.isInitialLoading {
                ProgressView()
            }
        }
    }
}
