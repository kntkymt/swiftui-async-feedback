public protocol SystemProtocol: Sendable {
    associatedtype State: Sendable
    associatedtype Event: Sendable

    // not sendable because of inout
    typealias Reducer = (inout State, Event) -> Void

    func reducer() -> Reducer
    func feedbacks() -> [Feedback<Self>]
}
