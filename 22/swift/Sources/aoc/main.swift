import Foundation
import Parsing

// MARK: - Models

enum PowerState {
  case on, off
}

extension ClosedRange where Bound == Int {
  var size: Int { abs(upperBound - lowerBound) + 1 }

  func completelyContains(_ other: Self) -> Bool {
    return lowerBound <= other.lowerBound && upperBound >= other.upperBound
  }

  func splitting(on other: Self) -> Set<Self> {
    if other.completelyContains(self) {
      return [self]
    } else if lowerBound < other.lowerBound, upperBound > other.upperBound {
      return [
        (lowerBound...(other.lowerBound - 1)),
        other,
        ((other.upperBound + 1)...upperBound),
      ]
    } else if other.lowerBound <= lowerBound {
      return [lowerBound...other.upperBound, (other.upperBound + 1)...upperBound]
    } else {
      return [lowerBound...(other.lowerBound - 1), other.lowerBound...upperBound]
    }
  }
}

struct CubeRange: Hashable {
  var x: ClosedRange<Int>
  var y: ClosedRange<Int>
  var z: ClosedRange<Int>

  var size: Int { x.size * y.size * z.size }

  static let small = CubeRange(x: -50...50, y: -50...50, z: -50...50)
  var isSmall: Bool { CubeRange.small.completelyContains(self) }

  func completelyContains(_ other: CubeRange) -> Bool {
    x.completelyContains(other.x) && y.completelyContains(other.y) && z.completelyContains(other.z)
  }

  func intersects(_ other: CubeRange) -> Bool {
    x.overlaps(other.x) && y.overlaps(other.y) && z.overlaps(other.z)
  }

  func union(with other: CubeRange) -> Set<CubeRange> {
    let otherSet = Set([other])
    if !intersects(other) {
      return otherSet.union([self])
    } else if other.completelyContains(self) {
      return otherSet
    }

    return otherSet.union(
      x.splitting(on: other.x).flatMap { xRange in
        y.splitting(on: other.y).flatMap { yRange in
          z.splitting(on: other.z).compactMap { zRange in
            let new = CubeRange(x: xRange, y: yRange, z: zRange)
            return other.completelyContains(new) ? nil : new
          }
        }
      }
    )
  }
}

struct RebootState {
  let power: PowerState
  let cubeRange: CubeRange
}

extension Sequence where Element == RebootState {
  func numberOfOnCubes() -> Int {
    self
      .reduce(into: Set<CubeRange>()) { cubeRanges, state in
        if cubeRanges.isEmpty {
          if state.power == .on {
            cubeRanges = [state.cubeRange]
          }
        } else {
          cubeRanges = Set(cubeRanges.flatMap { $0.union(with: state.cubeRange) })
          if state.power == .off {
            cubeRanges.remove(state.cubeRange)
          }
        }
      }
      .map(\.size)
      .reduce(0, +)
  }
}

// MARK: - Parsers

let powerState = "on".map { PowerState.on }
  .orElse("off".map { .off })

let range = Int.parser()
  .skip("..")
  .take(Int.parser())
  .map(ClosedRange.init)

let cubeRange = Skip("x=")
  .take(range)
  .skip(",y=")
  .take(range)
  .skip(",z=")
  .take(range)
  .map(CubeRange.init)

let rebootState = powerState
  .skip(" ")
  .take(cubeRange)
  .map(RebootState.init)

let parser = Many(rebootState, separator: "\n")

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let states = parser.parse(&input)!

// MARK: - Parts 1 & 2

func partOne() -> Int {
  states
    .filter(\.cubeRange.isSmall)
    .numberOfOnCubes()
}

func partTwo() -> Int {
  states
    .numberOfOnCubes()
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
