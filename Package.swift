// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "swiftui-async-feedback",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
    ],
    products: [
        .library(
            name: "AsyncFeedback",
            targets: ["AsyncFeedback"]
        ),
        .library(
            name: "AsyncFeedbackTestSupport",
            targets: ["AsyncFeedbackTestSupport"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "AsyncFeedback",
            dependencies: [.product(name: "AsyncAlgorithms", package: "swift-async-algorithms")]
        ),
        .testTarget(
            name: "AsyncFeedbackTests",
            dependencies: ["AsyncFeedback"]
        ),
        .target(
            name: "AsyncFeedbackTestSupport",
            dependencies: ["AsyncFeedback"]
        ),
        .testTarget(
            name: "AsyncFeedbackTestSupportTests",
            dependencies: ["AsyncFeedbackTestSupport"]
        ),
    ]
)
