// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CleanApple",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "CleanApple", targets: ["CleanApple"])
    ],
    targets: [
        .executableTarget(
            name: "CleanApple",
            path: "Targets/CleanApple/Sources"
        ),
        .testTarget(
            name: "CleanAppleTests",
            dependencies: ["CleanApple"],
            path: "Targets/CleanApple/Tests"
        )
    ]
)
