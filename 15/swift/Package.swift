// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "aoc",
  products: [
    .executable(
      name: "aoc",
      targets: ["aoc"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-collections", .branch("feature/SortedCollections")),
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.4.0")
  ],
  targets: [
    .executableTarget(
      name: "aoc",
      dependencies: [
        .product(name: "Collections", package: "swift-collections"),
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),
  ]
)
