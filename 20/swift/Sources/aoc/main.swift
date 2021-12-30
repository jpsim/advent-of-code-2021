import Foundation
import Parsing

// MARK: - Models

enum Pixel {
  case dark, light
}

struct Point: Hashable, Comparable {
  let x: Int
  let y: Int

  static func < (lhs: Point, rhs: Point) -> Bool {
    (lhs.y, lhs.x) < (rhs.y, rhs.x)
  }

  var ninePointGrid: [Point] {
    [
      Point(x: x - 1, y: y - 1),
      Point(x: x + 0, y: y - 1),
      Point(x: x + 1, y: y - 1),
      Point(x: x - 1, y: y + 0),
      Point(x: x + 0, y: y + 0),
      Point(x: x + 1, y: y + 0),
      Point(x: x - 1, y: y + 1),
      Point(x: x + 0, y: y + 1),
      Point(x: x + 1, y: y + 1),
    ]
  }
}

struct Image {
  let points: [Point: Pixel]

  var numberOfLitPixels: Int {
    points.values
      .filter { $0 == .light }
      .count
  }

  func algorithmIndex(for point: Point) -> Int {
    point.ninePointGrid
      .compactMap { points[$0] }
      .reduce(0) { int, pixel in
        (int << 1) + (pixel == .light ? 1 : 0)
      }
  }

  func padding(_ padding: Int) -> Image {
    let maxPoint = points.keys.max()!
    let newMaxX = (padding * 2) + maxPoint.x
    let newMaxY = (padding * 2) + maxPoint.y
    return Image(
      points: (0...newMaxX)
        .reduce([:]) { newPoints, x in
          (0...newMaxY).reduce(into: newPoints) { newPoints, y in
            newPoints[Point(x: x, y: y)] = points[Point(x: x - padding, y: y - padding)] ?? .dark
          }
        }
    )
  }

  func process(with algorithm: Algorithm) -> Image {
    Image(
      points: Dictionary(
        uniqueKeysWithValues: points.map { point, _ in
          (point, algorithm.pixel(atIndex: algorithmIndex(for: point)))
      })
    )
  }

  func process(with algorithm: Algorithm, times: Int) -> Image {
    (0..<times).reduce(self) { result, _ in
      result.process(with: algorithm)
    }
  }

  func numberOfLitPixels(afterProcessing times: Int, with algorithm: Algorithm) -> Int {
    padding(times + 1)
      .process(with: algorithm, times: times)
      .numberOfLitPixels
  }
}

extension Image {
  init(lines: [[Pixel]]) {
    points = lines
      .enumerated()
      .reduce(into: [:]) { points, yAndLine in
        let (y, line) = yAndLine
        for (x, pixel) in line.enumerated() {
          points[Point(x: x, y: y)] = pixel
        }
      }
  }
}

struct Algorithm {
  let pixels: [Pixel]

  func pixel(atIndex index: Int) -> Pixel {
    pixels[index]
  }
}

// MARK: - Parsers

let pixel = "#".map { Pixel.light }
  .orElse(".".map { .dark })

let pixelLine = Many(pixel, atLeast: 1)

let image = Many(pixelLine, separator: "\n")
  .map(Image.init)

let parser = pixelLine
  .map(Algorithm.init)
  .skip("\n\n")
  .take(image)

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let (parsedAlgorithm, parsedImage) = parser.parse(&input)!

// MARK: - Parts 1 & 2

func partOne() -> Int {
  parsedImage
    .numberOfLitPixels(afterProcessing: 2, with: parsedAlgorithm)
}

func partTwo() -> Int {
  parsedImage
    .numberOfLitPixels(afterProcessing: 50, with: parsedAlgorithm)
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
