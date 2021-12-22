import Algorithms
import Dispatch
import Foundation
import Parsing

// MARK: - Models

struct Dot: Hashable {
  let x: Int
  let y: Int
}

struct Grid: CustomStringConvertible {
  let dots: [Dot]
  let maxX: Int
  let maxY: Int

  init(dots: [Dot]) {
    self.dots = dots
    self.maxX = dots.map(\.x).max()!
    self.maxY = dots.map(\.y).max()!
  }

  init(dots: [Dot], maxX: Int, maxY: Int) {
    self.dots = dots
    self.maxX = maxX
    self.maxY = maxY
  }

  var description: String {
    (0...maxY)
      .map { y in
        (0...maxX)
          .map { Dot(x: $0, y: y) }
          .map(dots.contains)
          .map { $0 ? "#" : "." }
          .reduce("", +)
      }
      .joined(separator: "\n")
  }

  func folding(_ instruction: Instruction) -> Grid {
    var newDots = dots
    var newMaxX = maxX
    var newMaxY = maxY
    switch instruction {
    case .foldUp(let value):
      newMaxY = value - 1
      for y in (value + 1)...maxY {
        let newY = value - (y - value)
        let dotsInY = newDots.filter { $0.y == y }
        let foldedDotsInY = dotsInY.map { Dot(x: $0.x, y: newY) }
        newDots.removeAll(where: { $0.y == y })
        newDots.append(contentsOf: foldedDotsInY)
      }
    case .foldLeft(let value):
      newMaxX = value - 1
      for x in (value + 1)...maxX {
        let newX = value - (x - value)
        let dotsInX = newDots.filter { $0.x == x }
        let foldedDotsInX = dotsInX.map { Dot(x: newX, y: $0.y) }
        newDots.removeAll(where: { $0.x == x })
        newDots.append(contentsOf: foldedDotsInX)
      }
    }

    return Grid(dots: Array(Set(newDots)), maxX: newMaxX, maxY: newMaxY)
  }
}

enum Dimension {
  case x, y
}

enum Instruction {
  case foldUp(Int)
  case foldLeft(Int)
}

enum Line {
  case dot(Dot)
  case instruction(Instruction)
}

// MARK: - Parsers

let dot = Int.parser()
  .skip(",".utf8)
  .take(Int.parser())
  .map(Dot.init)
  .map(Line.dot)

let dimension = Parsers.OneOf(
  "x".utf8.map { Dimension.x },
  "y".utf8.map { .y }
)

let instruction = Skip(PrefixThrough("fold along ".utf8))
  .take(dimension)
  .skip("=".utf8)
  .take(Int.parser())
  .map { dimension, value -> Instruction in
    switch dimension {
    case .x:
      return .foldLeft(value)
    case .y:
      return .foldUp(value)
    }
  }
  .map(Line.instruction)

let line = dot
  .orElse(instruction)

let lines = Many(line, separator: "\n".utf8)

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...].utf8
let parsedInput = lines.parse(&input)!

let grid = Grid(dots: parsedInput.compactMap { line in
  if case .dot(let dot) = line {
    return dot
  } else {
    return nil
  }
})

let instructions = parsedInput.compactMap { line -> Instruction? in
  if case .instruction(let instruction) = line {
    return instruction
  } else {
    return nil
  }
}

// MARK: - Parts 1 & 2

func partOne() -> Int {
  grid.folding(instructions[0]).dots.count
}

func partTwo() -> String {
  instructions
    .reduce(grid) { $0.folding($1) }
    .description
}

print("Part 1:", partOne())
print("Part 2:")
print(partTwo())
