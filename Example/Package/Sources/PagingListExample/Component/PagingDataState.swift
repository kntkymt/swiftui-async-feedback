enum PagingDataState<V: Sendable, E: Error>: Sendable {
    case idle

    case initialLoading
    case retryLoading(E)
    case reLoading(V)

    case success(V)
    case loadingFailure(E)

    case paging(V)
    case pagingFailure(V, E)
}

extension PagingDataState {
    mutating func startLoading() {
        switch self {
        case .idle:
            self = .initialLoading

        case .success(let value),
                .pagingFailure(let value, _):
            self = .reLoading(value)

        case .loadingFailure(let error):
            self = .retryLoading(error)

        case .initialLoading,
                .retryLoading,
                .reLoading,
                .paging:
            return
        }
    }

    mutating func startPaging() {
        switch self {
        case .success(let value),
                .pagingFailure(let value, _):
            self = .paging(value)

        case .idle,
                .loadingFailure,
                .initialLoading,
                .retryLoading,
                .reLoading,
                .paging:
            return
        }
    }

    var isIdle: Bool {
        if case .idle = self {
            return true
        }

        return false
    }

    var isLoading: Bool {
        switch self {
        case .initialLoading,
                .retryLoading,
                .reLoading:

            return true

        default:
            return false
        }
    }

    var isPaging: Bool {
        if case .paging = self {
            return true
        }

        return false
    }

    var isInitialLoading: Bool {
        if case .initialLoading = self {
            return true
        }

        return false
    }

    var isSuccess: Bool {
        if case .success = self {
            return true
        }

        return false
    }

    var isFailure: Bool {
        switch self {
        case .loadingFailure,
                .pagingFailure:
            return true

        default:
            return false
        }
    }

    var isPagingFailure: Bool {
        if case .pagingFailure = self {
            return true
        }

        return false
    }

    var value: V? {
        switch self {
        case .reLoading(let value),
                .paging(let value),
                .success(let value),
                .pagingFailure(let value, _):
            return value

        default:
            return nil
        }
    }

    var error: E? {
        switch self {
        case .retryLoading(let error),
                .loadingFailure(let error),
                .pagingFailure(_, let error):
            return error

        default:
            return nil
        }
    }
}
