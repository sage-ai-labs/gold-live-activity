// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CountdownTests",
    targets: [
        .target(name: "CountdownLogic"),
        .testTarget(
            name: "CountdownTests",
            dependencies: ["CountdownLogic"]
        ),
    ]
)
