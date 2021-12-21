import Algorithms
import Foundation
import Parsing

// MARK: - Models

struct Point: Hashable, Comparable {
  static func < (lhs: Point, rhs: Point) -> Bool {
    (lhs.x, lhs.y) < (rhs.x, rhs.y)
  }

  let x: Int
  let y: Int
}

enum Height: Int, Comparable, Hashable {
  static func < (lhs: Height, rhs: Height) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

  case zero, one, two, three, four, five, six, seven, eight, nine

  var riskLevel: Int {
    rawValue + 1
  }
}

struct Line {
  let points: [Height]
}

extension Array where Element == PointWithHeight {
  func lowPointCandidates() -> [PointWithHeight] {
    var results = [PointWithHeight]()
    let windowsOfThree = self.windows(ofCount: 3)
    let middles = windowsOfThree
      .map(Array.init)
      .filter { items in
        items[0].height > items[1].height && items[2].height > items[1].height
      }
      .map { $0[1] }
    results.append(contentsOf: middles)

    let firstEdge = self.prefix(2)
    if firstEdge.first!.height < firstEdge.last!.height {
      results.append(firstEdge.first!)
    }

    let lastEdge = self.suffix(2)
    if lastEdge.last!.height < lastEdge.first!.height {
      results.append(lastEdge.last!)
    }

    return results
  }
}

struct Basin {
  let points: [PointWithHeight]
  var size: Int { points.count }
}

struct PointWithHeight: Hashable, Comparable {
  static func < (lhs: PointWithHeight, rhs: PointWithHeight) -> Bool {
    (lhs.point, lhs.height) < (rhs.point, rhs.height)
  }

  let point: Point
  let height: Height
}

extension Collection where Element == PointWithHeight {
  func points(adjacentTo point: Point) -> [PointWithHeight] {
    let adjacentPositions = [
      Point(x: point.x + 1, y: point.y),
      Point(x: point.x - 1, y: point.y),
      Point(x: point.x, y: point.y + 1),
      Point(x: point.x, y: point.y - 1),
    ]
    return filter { element in
      adjacentPositions.contains(element.point)
    }
  }

  func points(adjacentTo points: [Point]) -> [PointWithHeight] {
    Array(
      points
        .flatMap(points(adjacentTo:))
        .uniqued()
    )
  }
}

struct Grid {
  let points: [Point: Height]
  let maxPoint: Point

  init(lines: [Line]) {
    var points = [Point: Height]()
    for (y, line) in lines.enumerated() {
      for (x, height) in line.points.enumerated() {
        points[Point(x: x, y: y)] = height
      }
    }
    self.points = points
    self.maxPoint = points.keys.max()!
  }

  func getLowPoints() -> [PointWithHeight] {
    let xLowPointCandidates = (0...maxPoint.y).flatMap { y -> [PointWithHeight] in
      points
        .filter { $0.key.y == y }
        .sorted(by: { $0.key.x < $1.key.x })
        .map(PointWithHeight.init)
        .lowPointCandidates()
    }
    let yLowPointCandidates = (0...maxPoint.x).flatMap { x -> [PointWithHeight] in
      points
        .filter { $0.key.x == x }
        .sorted(by: { $0.key.y < $1.key.y })
        .map(PointWithHeight.init)
        .lowPointCandidates()
    }

    return Set(xLowPointCandidates)
      .intersection(yLowPointCandidates)
      .sorted()
  }

  func getBasins() -> [Basin] {
    var basins = [Basin]()
    var eligiblePoints = points
      .map(PointWithHeight.init)
    eligiblePoints
      .removeAll(where: { $0.height == .nine })

    let lowPoints = getLowPoints()
    for lowPoint in lowPoints {
      eligiblePoints.removeAll(where: { $0 == lowPoint })
      var basinPoints = [lowPoint]
      var finishedBasin = false
      while !finishedBasin {
        let adjacentPoints = eligiblePoints.points(adjacentTo: basinPoints.map(\.point))
        if adjacentPoints.isEmpty {
          finishedBasin = true
        } else {
          eligiblePoints.removeAll(where: adjacentPoints.contains)
          basinPoints.append(contentsOf: adjacentPoints)
        }
      }
      basins.append(Basin(points: basinPoints))
    }

    assert(eligiblePoints.isEmpty)
    return basins
  }
}

// MARK: - Parsers

let point = OneOfMany(
  "0".map { Height.zero },
  "1".map { .one },
  "2".map { .two },
  "3".map { .three },
  "4".map { .four },
  "5".map { .five },
  "6".map { .six },
  "7".map { .seven },
  "8".map { .eight },
  "9".map { .nine }
)

let line = Many(point)
  .map(Line.init)
let lines = Many(line, separator: "\n")
let grid = lines
  .map(Grid.init)

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let parsedInput = grid.parse(&input)!

// MARK: - Parts 1 & 2

func partOne() -> Int {
  return parsedInput.getLowPoints()
    .reduce(0) { sum, lowPoint in
      sum + lowPoint.height.riskLevel
    }
}

func partTwo() -> Int {
  return parsedInput.getBasins()
    .map(\.size)
    .sorted()
    .suffix(3)
    .reduce(1, *)
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
