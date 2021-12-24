import Foundation
import Parsing

// MARK: - Models

struct Velocity {
  let x: Int
  let y: Int
}

struct Point {
  let x: Int
  let y: Int

  func nextPoint(with velocity: Velocity) -> (Point, Velocity) {
    let nextPoint = Point(x: x + velocity.x, y: y + velocity.y)
    let nextXVelocity: Int
    if velocity.x == 0 {
      nextXVelocity = 0
    } else {
      nextXVelocity = velocity.x + (velocity.x > 0 ? -1 : 1)
    }
    let nextVelocity = Velocity(x: nextXVelocity, y: velocity.y - 1)
    return (nextPoint, nextVelocity)
  }
}

struct Trench {
  let xRange: ClosedRange<Int>
  let yRange: ClosedRange<Int>

  func contains(_ point: Point) -> Bool {
    xRange.contains(point.x) && yRange.contains(point.y)
  }

  var nearestPoint: Point { Point(x: xRange.lowerBound, y: yRange.upperBound) }
  var furthestPoint: Point { Point(x: xRange.upperBound, y: yRange.lowerBound) }
}

struct Path {
  let positions: [Point]

  var maxY: Int { positions.map(\.y).max()! }

  init(initialVelocity: Velocity, start: Point, furthestPoint: Point) {
    var nextPoint = start
    var nextVelocity = initialVelocity
    var positions = [start]
    while nextPoint.x <= furthestPoint.x && nextPoint.y >= furthestPoint.y {
      (nextPoint, nextVelocity) = nextPoint.nextPoint(with: nextVelocity)
      positions.append(nextPoint)
    }
    self.positions = positions
  }
}

struct Simulation {
  let trench: Trench
  let start: Point

  func generatePaths() -> [Path] {
    var minXVelocity = 1
    let nearestTrenchPoint = trench.nearestPoint
    while (1...minXVelocity).reduce(0, +) < nearestTrenchPoint.x {
      minXVelocity += 1
    }

    let furthestTrenchPoint = trench.furthestPoint
    let xVelocityRange = minXVelocity...furthestTrenchPoint.x
    let yVelocityRange = furthestTrenchPoint.y...(-furthestTrenchPoint.y)
    let velocityCandidates = xVelocityRange.flatMap { x in
      yVelocityRange.map { y in
        Velocity(x: x, y: y)
      }
    }

    let furthestPoint = trench.furthestPoint
    return velocityCandidates
      .map { Path(initialVelocity: $0, start: start, furthestPoint: furthestPoint) }
      .filter { $0.positions.contains(where: trench.contains) }
  }
}

// MARK: - Parsers

let range = Int.parser()
  .skip("..")
  .take(Int.parser())
  .map(ClosedRange.init)

let parser = Skip("target area: x=")
  .take(range)
  .skip(", y=")
  .take(range)
  .map(Trench.init)

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let trench = parser.parse(&input)!
let start = Point(x: 0, y: 0)
let simulation = Simulation(trench: trench, start: start)
let paths = simulation.generatePaths()

// MARK: - Parts 1 & 2

func partOne() -> Int {
  paths
    .map(\.maxY)
    .max()!
}

func partTwo() -> Int {
  paths.count
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
