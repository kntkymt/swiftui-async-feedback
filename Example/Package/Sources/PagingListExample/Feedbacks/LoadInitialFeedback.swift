import AsyncFeedback
import Foundation

extension Feedback where System == PagingListScreenSystem {
    static func loadInitial(api: API) -> Self {
        Feedback(.onChanged(\.postStatus.isLoading)) { state in
            guard state.postStatus.isLoading else { return nil }

            do {
                let posts = try await api.getPosts(0, 20)
                return .loaded(.success(posts))
            } catch {
                return .loaded(.failure(error))
            }
        }
    }
}
