import SortedCollections
import Foundation
import Parsing

// MARK: - Dijkstra

// From: https://www.fivestars.blog/articles/dijkstra-algorithm-swift/

final class Node<T: Hashable>: Hashable {
  let data: T
  private var visited = false
  private var connections: [Connection<T>] = []

  init(data: T) {
    self.data = data
  }

  func shortestPath(to destination: Node<T>) -> Path<T>? {
    // the frontier is made by a path that starts nowhere and ends in self
    var frontier: SortedSet = [Path(to: self)]

    while !frontier.isEmpty {
      let cheapestPathInFrontier = frontier.removeFirst() // getting the cheapest path available
      if cheapestPathInFrontier.node.visited {
        // making sure we haven't visited the node already
        continue
      } else if cheapestPathInFrontier.node === destination {
        return cheapestPathInFrontier // found the cheapest path 😎
      }

      cheapestPathInFrontier.node.visited = true

      for connection in cheapestPathInFrontier.node.connections where !connection.to.visited { // adding new paths to our frontier
        let path = Path(to: connection.to, via: connection, previousPath: cheapestPathInFrontier)
        frontier.insert(path)
      }
    } // end while
    return nil // we didn't find a path 😣
  }

  func add(_ connection: Connection<T>) {
    connections.append(connection)
  }

  static func == (lhs: Node<T>, rhs: Node<T>) -> Bool {
    (lhs.data, lhs.visited, lhs.connections) == (rhs.data, rhs.visited, rhs.connections)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(data)
    hasher.combine(visited)
    hasher.combine(connections)
  }
}

final class Connection<T: Hashable>: Hashable {
  let to: Node<T>
  let weight: Int

  init(to node: Node<T>, weight: Int) {
    self.to = node
    self.weight = weight
  }

  static func == (lhs: Connection<T>, rhs: Connection<T>) -> Bool {
    (lhs.to, lhs.weight) == (rhs.to, rhs.weight)
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(to)
    hasher.combine(weight)
  }
}

final class Path<T: Hashable>: Comparable {
  let cumulativeWeight: Int
  let node: Node<T>
  let previousPath: Path?

  var array: [Node<T>] {
    var array = [self.node]

    var iterativePath = self
    while let path = iterativePath.previousPath {
      array.append(path.node)
      iterativePath = path
    }

    return array
  }

  init(to node: Node<T>, via connection: Connection<T>? = nil, previousPath path: Path<T>? = nil) {
    if let previousPath = path, let viaConnection = connection {
      self.cumulativeWeight = viaConnection.weight + previousPath.cumulativeWeight
    } else {
      self.cumulativeWeight = 0
    }

    self.node = node
    self.previousPath = path
  }

  static func < (lhs: Path<T>, rhs: Path<T>) -> Bool {
    lhs.cumulativeWeight < rhs.cumulativeWeight
  }

  static func == (lhs: Path<T>, rhs: Path<T>) -> Bool {
    (lhs.node, lhs.cumulativeWeight) == (rhs.node, rhs.cumulativeWeight)
  }
}

// MARK: - Models

struct RiskLevel: Hashable {
  let value: Int

  init(value: Int) {
    if value > 9 {
      self.value = (value + 1) % 10
    } else {
      self.value = value
    }
  }
}

struct Point: Hashable, Comparable {
  let x: Int
  let y: Int

  static func < (lhs: Point, rhs: Point) -> Bool {
    (lhs.y, lhs.x) < (rhs.y, rhs.x)
  }

  var neighbors: [Point] {
    [
      Point(x: x + 0, y: y - 1),
      Point(x: x - 1, y: y + 0),
      Point(x: x + 0, y: y + 1),
      Point(x: x + 1, y: y + 0),
    ]
  }
}

struct PointWithRiskLevel: Hashable {
  let point: Point
  let riskLevel: RiskLevel
}

struct Grid {
  private var points: [Point: RiskLevel]

  var maxPoint: Point {
    points.keys.max()!
  }

  func accessiblePoints(from start: Point) -> [PointWithRiskLevel] {
    start.neighbors
      .filter { points[$0] != nil }
      .map { PointWithRiskLevel(point: $0, riskLevel: points[$0]!) }
  }

  init(lines: [[RiskLevel]]) {
    points = lines
      .enumerated()
      .reduce(into: [:]) { points, yAndLine in
        let (y, line) = yAndLine
        for (x, riskLevel) in line.enumerated() {
          points[Point(x: x, y: y)] = riskLevel
        }
      }
  }

  mutating func extend(times: Int) {
    let maxPoint = self.maxPoint
    let pointsExtendedInX = (1..<times).reduce(into: points) { result, multiplier in
      for (point, riskLevel) in points {
        let newPoint = Point(x: point.x + (multiplier * (maxPoint.x + 1)), y: point.y)
        result[newPoint] = RiskLevel(value: riskLevel.value + multiplier)
      }
    }

    points = (1..<times).reduce(into: pointsExtendedInX) { result, multiplier in
      for (point, riskLevel) in pointsExtendedInX {
        let newPoint = Point(x: point.x, y: point.y + (multiplier * (maxPoint.y + 1)))
        result[newPoint] = RiskLevel(value: riskLevel.value + multiplier)
      }
    }
  }

  func lowestRiskLevelFromStartToEnd() -> Int {
    let pointsWithLevels = points
      .map(PointWithRiskLevel.init)

    let nodes = pointsWithLevels
      .map(Node.init)

    let pointToNodeMap = Dictionary(uniqueKeysWithValues: zip(pointsWithLevels.map(\.point), nodes))

    var addedPoints: Set<[PointWithRiskLevel]> = []
    for node in nodes {
      let accessiblePoints = accessiblePoints(from: node.data.point)
      for point in accessiblePoints where !addedPoints.contains([node.data, point]) {
        if let connected = pointToNodeMap[point.point] {
          node.add(Connection(to: connected, weight: point.riskLevel.value))
          addedPoints.insert([node.data, point])
        }
      }
    }

    let start = pointToNodeMap[Point(x: 0, y: 0)]!
    let end = pointToNodeMap[maxPoint]!
    return start
      .shortestPath(to: end)!
      .array
      .dropLast()
      .map(\.data.riskLevel.value)
      .reduce(0, +)
  }
}

// MARK: - Parsers

let riskLevel = Prefix<Substring.UTF8View>(1)
  .pipe(Int.parser())
  .map(RiskLevel.init)

let parser = Many(Many(riskLevel), separator: "\n".utf8)
  .map(Grid.init)

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...].utf8
let grid = parser.parse(&input)!

// MARK: - Parts 1 & 2

func partOne() -> Int {
  grid.lowestRiskLevelFromStartToEnd()
}

func partTwo() -> Int {
  var grid = grid
  grid.extend(times: 5)
  return grid.lowestRiskLevelFromStartToEnd()
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
