// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "aoc",
  platforms: [
      .macOS(.v11),
  ],
  products: [
    .executable(
      name: "aoc",
      targets: ["aoc"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.4.0")
  ],
  targets: [
    .executableTarget(
      name: "aoc",
      dependencies: [
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),
  ]
)
