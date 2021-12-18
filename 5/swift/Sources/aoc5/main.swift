import Parsing

// MARK: - Models

struct Coordinate: Hashable {
  let x: Int
  let y: Int
}

struct VentLine {
  let start: Coordinate
  let end: Coordinate

  var isHorizontal: Bool {
    start.x == end.x || start.y == end.y
  }

  var isDiagonal: Bool {
    abs(start.x - end.x) == abs(start.y - end.y)
  }

  var minX: Int { min(start.x, end.x) }
  var maxX: Int { max(start.x, end.x) }
  var minY: Int { min(start.y, end.y) }
  var maxY: Int { max(start.y, end.y) }

  var interpolatedCoordinates: [Coordinate] {
    if start.x == end.x {
      return (minY...maxY).map { Coordinate(x: start.x, y: $0) }
    } else if start.y == end.y {
      return (minX...maxX).map { Coordinate(x: $0, y: start.y) }
    }

    // Assuming diagonal
    let steps = abs(start.x - end.x) + 1
    let xDirection = start.x < end.x ? 1 : -1
    let yDirection = start.y < end.y ? 1 : -1
    return (0..<steps).map { step in
      Coordinate(
        x: start.x + (step * xDirection),
        y: start.y + (step * yDirection)
      )
    }
  }
}

struct Grid {
  let rows: [[Int]]
  init(_ lines: [VentLine]) {
    let coordinateOverlapCounts = lines
      .flatMap(\.interpolatedCoordinates)
      .reduce(into: [:]) { counts, coordinate in counts[coordinate, default: 0] += 1 }
    rows = (0...maxY).map { y -> [Int] in
      (0...maxX).map { x -> Int in
        coordinateOverlapCounts[Coordinate(x: x, y: y)] ?? 0
      }
    }
  }

  var prettyPrinted: String {
    return rows
      .map { row in
        row
          .map { $0 == 0 ? "." : "\($0)" }
          .joined()
      }
      .joined(separator: "\n")
  }

  var pointsWhereTwoOrMoreLinesOverlap: Int {
    rows
      .flatMap { $0 }
      .map { $0 >= 2 ? 1 : 0 }
      .reduce(0, +)
  }
}

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let coordinate = Int.parser()
  .skip(",")
  .take(Int.parser())
  .map(Coordinate.init)
let ventLine = coordinate
  .skip(" -> ")
  .take(coordinate)
  .map(VentLine.init)

let ventLines = Many(ventLine, separator: "\n")

// MARK: - Part 1

print("# Part 1")

let inputLines = ventLines.parse(&input)!
let maxX = inputLines
  .flatMap { [$0.start.x, $0.end.x] }
  .max()!

let maxY = inputLines
  .flatMap { [$0.start.y, $0.end.y] }
  .max()!

let part1Lines = inputLines.filter(\.isHorizontal)
let part1Grid = Grid(part1Lines)
// print(part1Grid.prettyPrinted)
print("\(part1Grid.pointsWhereTwoOrMoreLinesOverlap) points have at least two lines overlapping")

// MARK: - Part 2

print("# Part 2")
let part2Lines = inputLines.filter { $0.isHorizontal || $0.isDiagonal }
let part2Grid = Grid(part2Lines)
// print(part2Grid.prettyPrinted)
print("\(part2Grid.pointsWhereTwoOrMoreLinesOverlap) points have at least two lines overlapping")
