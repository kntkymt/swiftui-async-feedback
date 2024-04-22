import Foundation

struct Post: Equatable, Identifiable {
    var id: Int
    var title: String
}

enum APIError: Error {
    case network
}

struct API {
    let getPosts: (_ minId: Int, _ count: Int) async throws -> [Post]
}

extension API {
    static var real: API = API { minId, count in
        try await Task.sleep(for: .seconds(2))

        if Int.random(in: 0..<5) == 0 {
            throw APIError.network
        }

        return (0..<count).map { Post(id: minId + $0, title: "post \(minId + $0)") }
    }
}
