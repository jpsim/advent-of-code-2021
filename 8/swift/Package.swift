// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "aoc8",
  products: [
    .executable(
      name: "aoc8",
      targets: ["aoc8"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.4.0")
  ],
  targets: [
    .executableTarget(
      name: "aoc8",
      dependencies: [
        .product(name: "Algorithms", package: "swift-algorithms"),
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),
  ]
)
