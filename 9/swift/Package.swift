// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "aoc9",
  products: [
    .executable(
      name: "aoc9",
      targets: ["aoc9"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.4.0")
  ],
  targets: [
    .executableTarget(
      name: "aoc9",
      dependencies: [
        .product(name: "Algorithms", package: "swift-algorithms"),
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),
  ]
)
