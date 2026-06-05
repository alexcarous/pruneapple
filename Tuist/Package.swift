// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PruneappleDependencies",
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle.git", exact: "2.6.4")
    ]
)
