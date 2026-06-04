import ProjectDescription

let project = Project(
    name: "CleanApple",
    targets: [
        .target(
            name: "CleanApple",
            destinations: .macOS,
            product: .app,
            bundleId: "us.caro.alex.CleanApple",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: ["Targets/CleanApple/Sources/**"],
            resources: ["Targets/CleanApple/Resources/**"],
            entitlements: "Targets/CleanApple/Resources/CleanApple.entitlements"
        ),
        .target(
            name: "CleanAppleTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.cleanapple.apptests",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: ["Targets/CleanApple/Tests/**"],
            dependencies: [
                .target(name: "CleanApple")
            ]
        )
    ]
)
