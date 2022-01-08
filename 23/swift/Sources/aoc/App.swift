import Foundation
import Parsing

// MARK: - Parallel Processing

extension Sequence where Element: Sendable {
  func asyncFlatMap<T: Sequence>(
    _ transform: (Element) async -> T
  ) async -> [T.Element] {
    var values = [T.Element]()
    for element in self {
      await values.append(contentsOf: transform(element))
    }
    return values
  }

  func concurrentFlatMap<T: Sequence>(
    withPriority priority: TaskPriority? = nil,
    _ transform: @Sendable (Element) async -> T
  ) async -> [T.Element] {
    await withoutActuallyEscaping(transform) { transform in
      await map { element in
        Task(priority: priority) {
          await transform(element)
        }
      }
      .asyncFlatMap { task in
        await task.value
      }
    }
  }
}

// MARK: - Models

enum AmphipodType: Hashable {
  case amber, bronze, copper, desert

  var stepEnergy: Int {
    switch self {
    case .amber:  return 1
    case .bronze: return 10
    case .copper: return 100
    case .desert: return 1000
    }
  }

  var expectedXPosition: Int {
    switch self {
    case .amber:  return 3
    case .bronze: return 5
    case .copper: return 7
    case .desert: return 9
    }
  }

  func possibleFinalPositions() -> [Point] {
    [5, 4, 3, 2]
      .map { Point(x: expectedXPosition, y: $0) }
  }
}

struct Point: Hashable {
  let x: Int
  let y: Int

  var up: Point    { Point(x: x + 0, y: y - 1) }
  var left: Point  { Point(x: x - 1, y: y + 0) }
  var down: Point  { Point(x: x + 0, y: y + 1) }
  var right: Point { Point(x: x + 1, y: y + 0) }

  var isBlockingRoom: Bool {
    y == 1 &&
      (x == 3 || x == 5 || x == 7 || x == 9)
  }

  func next(toward destination: Point) -> Point {
    if x == destination.x {
      return (y > destination.y) ? up : down
    } else if y > 1 {
      return up
    } else if x < destination.x {
      return right
    } else if x > destination.x {
      return left
    } else {
      fatalError("Unreachable")
    }
  }

  func path(to destination: Point) -> [Point] {
    var result = [next(toward: destination)]
    while let last = result.last, last != destination {
      result.append(last.next(toward: destination))
    }
    return result
  }
}

enum PointValue: Hashable {
  case nothing
  case wall
  case openSpace
  case amphipod(AmphipodType)

  var canBeSpace: Bool {
    switch self {
    case .nothing, .wall:
      return false
    case .openSpace, .amphipod:
      return true
    }
  }
}

struct Diagram: Hashable {
  var points: [Point: PointValue]
  var energy = 0
  var amphipodsToMove: [Point: AmphipodType]

  var isFinal: Bool { amphipodsToMove.isEmpty }

  func costOfMovingAmphipod(ofType amphipodType: AmphipodType, from origin: Point, to destination: Point) -> Int? {
    if points[destination] != .openSpace {
      return nil // Destination must be an open space
    } else if destination.isBlockingRoom {
      return nil // Destination cannot block a room
    } else if origin.y == 1 && amphipodType.expectedXPosition != destination.x {
      return nil // Already moved this amphipod once. Can only move it to its final position.
    }

    let path = origin.path(to: destination)
    if path.contains(where: { points[$0] != .openSpace }) {
      return nil // Amphipod blocking path
    }

    return path.count * amphipodType.stepEnergy
  }

  func movingAmphipod(ofType amphipodType: AmphipodType, from origin: Point, to destination: Point) -> Diagram? {
    guard let cost = costOfMovingAmphipod(ofType: amphipodType, from: origin, to: destination) else {
      return nil
    }

    var new = self
    new.points[destination] = new.points[origin]
    new.points[origin] = .openSpace
    new.energy += cost
    new.amphipodsToMove = new.points.amphipodsToMove()
    return new
  }

  func allPossibleMoves() -> [Diagram] {
    var possibleDestinations: Set<Point> = Set(
      points
        .filter { $0.value == .openSpace }
        .map(\.key)
    )

    // Prioritize moving an amphipod to its final position
    for (origin, amphipodType) in amphipodsToMove.sorted(by: { $0.value.stepEnergy > $1.value.stepEnergy }) {
      for destination in amphipodType.possibleFinalPositions() {
        possibleDestinations.remove(destination)
        if let moved = movingAmphipod(ofType: amphipodType, from: origin, to: destination),
           moved.points.isAtFinalPosition(point: destination, amphipodType: amphipodType)
        {
          return [moved]
        }
      }
    }

    // Otherwise, return all remaining possible intermediate moves for each amphipod
    return amphipodsToMove
      .flatMap { origin, amphipodType in
        possibleDestinations
          .compactMap { destination in
            movingAmphipod(ofType: amphipodType, from: origin, to: destination)
          }
      }
  }

  func leastFinalEnergy() async -> Int {
    var leastEnergy: Int?
    var attempts: Set = [self]

    while !attempts.isEmpty {
      attempts = Set(
        await attempts
          .concurrentFlatMap { $0.allPossibleMoves() }
      )

      let nextLeastEnergy = attempts
        .filter(\.isFinal)
        .map(\.energy)
        .min()

      if let nextLeastEnergy = nextLeastEnergy {
        leastEnergy = min(nextLeastEnergy, leastEnergy ?? nextLeastEnergy)
      }
    }

    // No more attempts possible
    return leastEnergy!
  }
}

extension Dictionary where Key == Point, Value == PointValue {
  func isAtFinalPosition(point: Point, amphipodType: AmphipodType) -> Bool {
    if amphipodType.expectedXPosition != point.x {
      return false // Amphipod is not at its expected X position
    }

    // Amphipod does not block another amphipod that is not at its expected X position
    return [point.down, point.down.down, point.down.down.down].allSatisfy { pointBelow in
      switch self[pointBelow] {
      case .amphipod(amphipodType), nil:
        return true
      default:
        return false
      }
    }
  }

  func amphipodsToMove() -> [Point: AmphipodType] {
    Dictionary<Point, AmphipodType>(
      uniqueKeysWithValues: self
        .compactMap { point, value -> (Point, AmphipodType)? in
          if case .amphipod(let type) = value,
             !isAtFinalPosition(point: point, amphipodType: type)
          {
            return (point, type)
          } else {
            return nil
          }
        }
    )
  }
}

extension Diagram {
  init(lines: [[PointValue]]) {
    points = lines
      .enumerated()
      .reduce(into: [:]) { points, yAndLine in
        let (y, line) = yAndLine
        for (x, value) in line.enumerated() where value.canBeSpace {
          points[Point(x: x, y: y)] = value
        }
      }
    amphipodsToMove = points.amphipodsToMove()
  }
}

// MARK: - Parsers

let amphipodType = OneOfMany(
  "A".map { AmphipodType.amber },
  "B".map { .bronze },
  "C".map { .copper },
  "D".map { .desert }
)

let pointValue = "#".map { PointValue.wall }
         .orElse(".".map { .openSpace })
         .orElse(" ".map { .nothing })
         .orElse(amphipodType.map(PointValue.amphipod))

let pointValueLine = Many(pointValue, atLeast: 1)
let parser = Many(pointValueLine, atLeast: 1, separator: "\n")
  .map(Diagram.init)

// MARK: - Parts 1 & 2

func partOne(input: String) async -> Int {
  var partOneInput = input[...]
  let diagram = parser.parse(&partOneInput)!
  return await diagram.leastFinalEnergy()
}

func partTwo(input: String) async -> Int {
  var lines = input.split(separator: "\n")
  lines.insert(
    contentsOf: [
      "  #D#C#B#A#",
      "  #D#B#A#C#",
    ],
    at: 3
  )

  var partTwoInput = lines.joined(separator: "\n")[...]
  let diagram = parser.parse(&partTwoInput)!
  return await diagram.leastFinalEnergy()
}

@main
struct App {
  static func main() async throws {
    let input = try String(contentsOfFile: "input.txt", encoding: .utf8)
    print("Part 1:", await partOne(input: input))
    print("Part 2:", await partTwo(input: input))
  }
}
