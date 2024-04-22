// swift-tools-version: 5.10
import PackageDescription

let asyncFeedback = Target.Dependency.product(name: "AsyncFeedback", package: "swiftui-async-feedback")
let asyncFeedbackTestSupport = Target.Dependency.product(name: "AsyncFeedbackTestSupport", package: "swiftui-async-feedback")

let package = Package(
    name: "Package",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "App", targets: ["App"]),
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .target(
            name: "App",
            dependencies: [
                "CounterExample",
                "TodoExample",
                "PagingListExample"
            ]
        ),
        .target(
            name: "CounterExample",
            dependencies: [asyncFeedback]
        ),
        .testTarget(
            name: "CounterExampleTests",
            dependencies: [
                "CounterExample",
                asyncFeedbackTestSupport
            ]
        ),
        .target(
            name: "TodoExample",
            dependencies: [asyncFeedback]
        ),
        .testTarget(
            name: "TodoExampleTests",
            dependencies: [
                "TodoExample",
                asyncFeedbackTestSupport
            ]
        ),
        .target(
            name: "PagingListExample",
            dependencies: [asyncFeedback]
        ),
        .testTarget(
            name: "PagingListExampleTests",
            dependencies: [
                "PagingListExample",
                asyncFeedbackTestSupport
            ]
        ),
    ]
)
