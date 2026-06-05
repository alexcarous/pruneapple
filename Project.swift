import ProjectDescription

let project = Project(
    name: "Pruneapple",
    targets: [
        .target(
            name: "Pruneapple",
            destinations: .macOS,
            product: .app,
            bundleId: "us.caro.alex.Pruneapple",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleIconFile": "AppIcon",
                "CFBundleDisplayName": "Pruneapple",
                "CFBundleName": "Pruneapple",
                "CFBundleShortVersionString": "1.0.0",
                "CFBundleVersion": "1",
                "NSHumanReadableCopyright": "Copyright © 2026 Alexander Caro.\nAll rights reserved.",
                "NSDesktopFolderUsageDescription": "Pruneapple requires access to your Desktop to calculate folder sizes.",
                "NSDocumentsFolderUsageDescription": "Pruneapple requires access to your Documents to calculate folder sizes.",
                "NSDownloadsFolderUsageDescription": "Pruneapple requires access to your Downloads to calculate folder sizes.",
                "NSRemovableVolumesUsageDescription": "Pruneapple requires access to external drives to scan their contents.",
                "NSNetworkVolumesUsageDescription": "Pruneapple requires access to network drives to scan their contents."
            ]),
            sources: ["Targets/Pruneapple/Sources/**"],
            resources: [
                "Targets/Pruneapple/Resources/Assets.xcassets"
            ],
            entitlements: "Targets/Pruneapple/Resources/Pruneapple.entitlements"
        ),
        .target(
            name: "PruneappleTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "us.caro.alex.PruneappleTests",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: ["Targets/Pruneapple/Tests/**"],
            dependencies: [
                .target(name: "Pruneapple")
            ]
        ),
        .target(
            name: "PruneappleUITests",
            destinations: .macOS,
            product: .uiTests,
            bundleId: "us.caro.alex.PruneappleUITests",
            deploymentTargets: .macOS("15.0"),
            infoPlist: .default,
            sources: ["Targets/Pruneapple/UITests/**"],
            dependencies: [
                .target(name: "Pruneapple")
            ]
        )
    ]
)
