// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "__0__",
    products: [
        .library(name: "__0__", targets: ["__0__"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "__0__",
            dependencies: ["__0__FFI"]
        ),
        .binaryTarget(
            name: "__0__FFI",
            path: "./Sources/__0__FFI.xcframework"
        ),
    ]
)
