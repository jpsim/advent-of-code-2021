// swift-tools-version:5.5

import PackageDescription

let package = Package(
  name: "aoc5",
  products: [
    .executable(
      name: "aoc5",
      targets: ["aoc5"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/pointfreeco/swift-parsing", from: "0.4.0")
  ],
  targets: [
    .executableTarget(
      name: "aoc5",
      dependencies: [
        .product(name: "Parsing", package: "swift-parsing"),
      ]
    ),
  ]
)
