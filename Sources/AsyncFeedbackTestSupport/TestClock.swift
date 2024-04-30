import Foundation

public final class TestClock: Clock, @unchecked Sendable {
    public struct Instant: InstantProtocol {
        public static var zero: Instant { Instant(offset: .zero) }

        public var offset: Duration

        public init(offset: Duration) {
            self.offset = offset
        }

        public func advanced(by duration: Duration) -> Instant {
            Instant(offset: offset + duration)
        }

        public func duration(to other: Instant) -> Duration {
            other.offset - offset
        }

        public static func < (_ lhs: Instant, _ rhs: Instant) -> Bool {
            lhs.offset < rhs.offset
        }

        public static func += (_ lhs: inout Instant, _ rhs: Duration) {
            lhs = lhs.advanced(by: rhs)
        }
    }

    struct WakeUp {
        var when: Instant
        var continuation: AsyncStream<Void>.Continuation

        init(when: Instant, continuation: AsyncStream<Void>.Continuation) {
            self.when = when
            self.continuation = continuation
        }
    }

    public var minimumResolution: Duration = .zero
    public private(set) var now: Instant

    private var noIdSleepCount = 0
    private var wakeUps: [AnyHashable: WakeUp] = [:]
    private let lock = NSLock()

    public init(initialInstant: Instant) {
        self.now = initialInstant
    }

    deinit {
        lock.withLock {
            wakeUps.values.forEach { $0.continuation.finish() }
        }
    }

    public func getAutoId(index: Int) -> String {
        "_auto_id_\(index)"
    }

    public func isSleeping<ID: Hashable>(id: ID) -> Bool {
        return lock.withLock {
            wakeUps[AnyHashable(id)] != nil
        }
    }

    public func sleep<ID: Hashable>(untilSuspendBy id: ID) async throws {
        while !isSleeping(id: id) {
            await Task.yield()
            try Task.checkCancellation()
        }
    }

    public func sleep<ID: Hashable>(id: ID, for duration: Duration, tolerance: Duration? = nil) async throws {
        try await sleep(id: id, until: lock.withLock({ now.advanced(by: duration) }), tolerance: tolerance)
    }

    public func sleep(until deadline: Instant, tolerance: Duration? = nil) async throws {
        let index = lock.withLock {
            let count = noIdSleepCount
            noIdSleepCount += 1
            return count
        }
        return try await sleep(id: getAutoId(index: index), until: deadline, tolerance: tolerance)
    }

    public func sleep<ID: Hashable>(id: ID, until deadline: Instant, tolerance: Duration? = nil) async throws {
        try Task.checkCancellation()

        let stream = AsyncStream<Void> { continuation in
            lock.withLock {
                if deadline <= now {
                    continuation.finish()
                } else {
                    wakeUps[AnyHashable(id)] = WakeUp(when: deadline, continuation: continuation)
                }
            }
        }
        // AsyncStreamはTaskのcancelでfinishが走るため
        // cancelをした瞬間にCancellelationErrorを投げることができる
        // 普通のContinuationでは無理
        for await _ in stream {}

        try Task.checkCancellation()
    }

    public func advance(by amount: Duration) {
        var shouldWakeUps = [WakeUp]()

        lock.withLock {
            now += amount
            for key in wakeUps.keys {
                guard let wakeup = wakeUps[key] else { continue }
                if wakeup.when <= now {
                    shouldWakeUps.append(wakeup)
                    wakeUps[key] = nil
                }
            }
        }

        shouldWakeUps.sort { $0.when < $1.when }
        for item in shouldWakeUps {
            item.continuation.finish()
        }
    }
}
