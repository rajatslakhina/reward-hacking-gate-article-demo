// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TaskIntegrity",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "TaskIntegrity", targets: ["TaskIntegrity"])
    ],
    targets: [
        .target(name: "TaskIntegrity"),
        .testTarget(name: "TaskIntegrityTests", dependencies: ["TaskIntegrity"])
    ]
)
