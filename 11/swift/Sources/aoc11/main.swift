import Algorithms
import Foundation
import Parsing

// MARK: - Models

enum EnergyLevel: Int, Hashable {
  case zero, one, two, three, four, five, six, seven, eight, nine

  func increased() -> EnergyLevel {
    EnergyLevel(rawValue: rawValue + 1) ?? .zero
  }
}

struct Line {
  let energyLevels: [EnergyLevel]
}

struct Point: Hashable {
  let x: Int
  let y: Int

  var neighbors: [Point] {
    [
      Point(x: x - 1, y: y - 1),
      Point(x: x - 1, y: y + 0),
      Point(x: x - 1, y: y + 1),
      Point(x: x + 0, y: y - 1),
      Point(x: x + 0, y: y + 1),
      Point(x: x + 1, y: y - 1),
      Point(x: x + 1, y: y + 0),
      Point(x: x + 1, y: y + 1),
    ]
  }
}

struct Grid {
  var points: [Point: EnergyLevel]

  init(lines: [Line]) {
    var points = [Point: EnergyLevel]()
    for (y, line) in lines.enumerated() {
      for (x, energyLevel) in line.energyLevels.enumerated() {
        points[Point(x: x, y: y)] = energyLevel
      }
    }
    self.points = points
  }

  mutating func advanceStep() -> Int {
    points = points.mapValues { $0.increased() }
    var seenFlashPoints = points
      .filter { $0.value == .zero }
      .map(\.key)
    var newFlashPoints = seenFlashPoints

    while !newFlashPoints.isEmpty {
      let pointsToIncrease = newFlashPoints.flatMap(\.neighbors)
      newFlashPoints.removeAll()
      points = Dictionary(
        uniqueKeysWithValues: points
          .map { key, value in
            var newValue = value
            for point in pointsToIncrease where point == key {
              if seenFlashPoints.contains(point) {
                continue
              }

              newValue = newValue.increased()
              if newValue == .zero {
                seenFlashPoints.append(point)
                newFlashPoints.append(point)
              }
            }

            return (key, newValue)
          }
      )
    }

    return seenFlashPoints.count
  }
}

// MARK: - Parsers

let energyLevel = OneOfMany(
  "0".map { EnergyLevel.zero },
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

let line = Many(energyLevel)
  .map(Line.init)
let lines = Many(line, separator: "\n")
  .map(Grid.init)

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let parsedInput = lines.parse(&input)!

// MARK: - Parts 1 & 2

func partOne() -> Int {
  var advancingGrid = parsedInput
  return (1...100)
    .reduce(0) { sum, _ in sum + advancingGrid.advanceStep() }
}

func partTwo() -> Int {
  var advancingGrid = parsedInput
  return (1...).first { _ in
    advancingGrid.advanceStep() == 100
  }!
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
