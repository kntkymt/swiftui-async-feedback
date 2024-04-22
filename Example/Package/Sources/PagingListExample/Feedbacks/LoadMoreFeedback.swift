import AsyncFeedback
import Foundation

extension Feedback where System == PagingListScreenSystem {
    static func loadMore(api: API) -> Self {
        Feedback(.onChanged(\.postStatus.isPaging)) { state in
            guard state.postStatus.isPaging, let posts = state.postStatus.value, let lastId = posts.last?.id else { return nil }

            do {
                let newPosts = try await api.getPosts(lastId + 1, 30)
                return .loadedMore(.success(newPosts))
            } catch {
                return .loadedMore(.failure(error))
            }
        }
    }
}
