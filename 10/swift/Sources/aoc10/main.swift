import Algorithms
import Foundation
import Parsing

// MARK: - Models

enum ChunkSide {
  case opening, closing
}

enum ChunkType {
  case round, square, curly, angle

  var corruptionPoints: Int {
    switch self {
    case .round:  return 3
    case .square: return 57
    case .curly:  return 1197
    case .angle:  return 25137
    }
  }

  var autocompletePoints: Int {
    switch self {
    case .round:  return 1
    case .square: return 2
    case .curly:  return 3
    case .angle:  return 4
    }
  }
}

struct ChunkDelimiter {
  let side: ChunkSide
  let type: ChunkType
}

enum LineState {
  case valid, incomplete([ChunkType]), corrupt(ChunkType)

  var corruptionPoints: Int {
    switch self {
    case .valid, .incomplete:
      return 0
    case .corrupt(let type):
      return type.corruptionPoints
    }
  }

  var autocompletePoints: Int {
    switch self {
    case .valid, .corrupt:
      return 0
    case .incomplete(let types):
      return types
        .map(\.autocompletePoints)
        .reduce(0) { result, points in
          (result * 5) + points
        }
    }
  }
}

struct Line {
  let delimiters: [ChunkDelimiter]
  var state: LineState {
    var openTypes = [ChunkType]()
    for delimiter in delimiters {
      if delimiter.side == .opening {
        openTypes.append(delimiter.type)
      } else if delimiter.type == openTypes.last {
        openTypes.removeLast()
      } else {
        return .corrupt(delimiter.type)
      }
    }

    return openTypes.isEmpty ? .valid : .incomplete(Array(openTypes.reversed()))
  }
}

// MARK: - Parsers

let delimiter = OneOfMany(
  "(".map { ChunkDelimiter(side: .opening, type: .round) },
  ")".map { ChunkDelimiter(side: .closing, type: .round) },
  "[".map { ChunkDelimiter(side: .opening, type: .square) },
  "]".map { ChunkDelimiter(side: .closing, type: .square) },
  "{".map { ChunkDelimiter(side: .opening, type: .curly) },
  "}".map { ChunkDelimiter(side: .closing, type: .curly) },
  "<".map { ChunkDelimiter(side: .opening, type: .angle) },
  ">".map { ChunkDelimiter(side: .closing, type: .angle) }
)

let line = Many(delimiter)
  .map(Line.init)
let lines = Many(line, separator: "\n")

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let parsedInput = lines.parse(&input)!
let lineStates = parsedInput
  .map(\.state)

// MARK: - Parts 1 & 2

func partOne() -> Int {
  return lineStates
    .map(\.corruptionPoints)
    .reduce(0, +)
}

func partTwo() -> Int {
  let sortedPoints = lineStates
    .map(\.autocompletePoints)
    .filter { $0 > 0 }
    .sorted()
  return sortedPoints[(sortedPoints.count - 1) / 2]
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
