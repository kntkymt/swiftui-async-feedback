import SwiftUI
import AsyncFeedback

struct PagingListScreenSystem: SystemProtocol {

    let dependency: Dependency

    struct Dependency {
        var api: API
    }

    struct State: Sendable {
        var postStatus: PagingDataState<[Post], any Error> = .idle
    }

    enum Event {
        case load
        case loadMore

        case loaded(Result<[Post], any Error>)
        case loadedMore(Result<[Post], any Error>)
    }

    func reducer() -> Reducer {
        { state, event in
            switch event {
            case .load:
                if state.postStatus.isLoading || state.postStatus.isPaging { return }
                state.postStatus.startLoading()

            case .loaded(.success(let posts)):
                state.postStatus = .success(posts)

            case .loaded(.failure(let error)):
                state.postStatus = .loadingFailure(error)

            case .loadMore:
                if state.postStatus.isLoading || state.postStatus.isPaging { return }
                state.postStatus.startPaging()

            case .loadedMore(.success(let posts)):
                guard let currentPosts = state.postStatus.value else { return }
                state.postStatus = .success(currentPosts + posts)

            case .loadedMore(.failure(let error)):
                guard let currentPosts = state.postStatus.value else { return }
                state.postStatus = .pagingFailure(currentPosts, error)
            }
        }
    }

    func feedbacks() -> [Feedback<Self>] {
        [
            .loadInitial(api: dependency.api),
            .loadMore(api: dependency.api)
        ]
    }
}

struct PagingListScreen: View {

    @ViewContext<PagingListScreenSystem>
    var context: PagingListScreenSystem.State

    init(dependency: PagingListScreenSystem.Dependency) {
        self._context = ViewContext(
            state: .init(),
            system: PagingListScreenSystem(dependency: dependency)
        )
    }

    var body: some View {
        PagingList(
            dataState: context.postStatus,
            listContent: listContent,
            onPaging: { _context.send(.loadMore) }
        )
        .refreshable {
            await _context.send(.load, suspendingWhile: context.postStatus.isLoading)
        }
        .onAppear {
            _context.send(.load)
        }
        .task {
            await _context.runFeedbackLoop()
        }
        .navigationTitle("Paging")
    }

    func listContent(posts: [Post]) -> some View {
        ForEach(posts) { post in
            Text(post.title)
        }
    }
}

#Preview {
    PagingListScreen(dependency: .init(api: .real))
}
