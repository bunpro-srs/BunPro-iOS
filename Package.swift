// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "BunPuro",
    products: [],
    dependencies: [
        // Simple Swift wrapper for Keychain that works on iOS, watchOS, tvOS and macOS.
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess.git", .upToNextMajor(from: "3.2.0")),

        // Advanced Operations in Swift
        .package(url: "https://github.com/ProcedureKit/ProcedureKit.git", .upToNextMajor(from: "5.2.0")),

        // Convenient logging during development & release in Swift
        .package(url: "https://github.com/SwiftyBeaver/SwiftyBeaver.git", .upToNextMajor(from: "1.7.0")),
    ],
    targets: [
        .target(
            name: "BunPuro",
            dependencies: [
                "KeychainAccess",
                "ProcedureKit",
                "ProcedureKitNetwork",
                "SwiftyBeaver",
            ],
            path: "BunPuro"
        ),
        .testTarget(
            name: "BunPuroTests",
            dependencies: [
                // add your dependencies scheme names here, for example:
                // "Project",
            ],
            path: "BunPuroTests"
        ),
        .target(
            name: "BunPuroKit",
            dependencies: [
                "KeychainAccess",
                "ProcedureKit",
                "ProcedureKitNetwork",
                "SwiftyBeaver",
            ],
            path: "BunPuroKit"
        ),
        .testTarget(
            name: "BunPuroKitTests",
            dependencies: [
                // add your dependencies scheme names here, for example:
                // "Project",
            ],
            path: "BunPuroKitTests"
        )
    ]
)
