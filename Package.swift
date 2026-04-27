// swift-tools-version: 5.9
import PackageDescription
import CompilerPluginSupport

let package = Package(
    name: "SwiftMapper",
    platforms: [.macOS(.v10_15), .iOS(.v13)],
    products: [
        .library(name: "SwiftMapper", targets: ["SwiftMapper"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    ],
    targets: [
        .macro(
            name: "SwiftMapperMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ]
        ),
        .target(
            name: "SwiftMapper",
            dependencies: ["SwiftMapperMacros"]
        ),
        
        .executableTarget(
            name: "SwiftMapperClient",
            dependencies: ["SwiftMapper"]
        ),
    ]
)
