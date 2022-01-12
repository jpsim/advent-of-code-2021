import Foundation
import Parsing

// MARK: - Models

enum Entry {
  case east, south, empty
}

// MARK: - Parsers

let entry = OneOfMany(
  ">".map { Entry.east },
  "v".map { .south },
  ".".map { .empty }
)

let entries = Many(entry, atLeast: 1)
let parser = Many(entries, separator: "\n")

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let parsed = parser.parse(&input)!

// MARK: - Computation

enum RollDirection {
  case forward, backward
}

enum RollAxis {
  case x, y
}

extension Array {
  func rolled<T>(direction: RollDirection, along axis: RollAxis) -> [[T]] where Element == [T] {
    switch axis {
    case .x:
      return map { element in
        var new = element
        switch direction {
        case .forward:
          new.insert(new.removeLast(), at: 0)
        case .backward:
          new.append(new.removeFirst())
        }
        return new
      }
    case .y:
      var new = self
      switch direction {
      case .forward:
        new.insert(new.removeLast(), at: 0)
      case .backward:
        new.append(new.removeFirst())
      }
      return new
    }
  }

  func and(_ other: Self) -> Self where Element == [Bool] {
    zip(self, other).map { row1, row2 in
      zip(row1, row2).map { $0 && $1 }
    }
  }

  mutating func set<T>(mask: [[Bool]], to value: T) where Element == [T] {
    for (y, line) in mask.enumerated() {
      for (x, on) in line.enumerated() where on {
        self[y][x] = value
      }
    }
  }
}

// MARK: - Part 1

func partOne() -> Int {
  var entries = parsed
  var moved = [true]

  while moved.suffix(2).contains(true) {
    for (entry, axis) in [(Entry.east, RollAxis.x), (.south, .y)] {
      let allowedMoves = entries.rolled(direction: .backward, along: axis)
        .map { outer in outer.map { $0 == .empty } }
        .and(entries.map { outer in outer.map { $0 == entry } })
      entries.set(mask: allowedMoves, to: .empty)
      entries.set(mask: allowedMoves.rolled(direction: .forward, along: axis), to: entry)
      moved.append(allowedMoves.contains(where: { $0.contains(true) }))
    }
  }

  return moved.count / 2
}

print(partOne())
