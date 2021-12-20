import Algorithms
import Foundation
import Parsing

// MARK: - Models

enum Segment: Hashable, CaseIterable {
  case a, b, c, d, e, f, g
}

enum Digit: Int {
  case zero, one, two, three, four, five, six, seven, eight, nine

  static func from(_ segments: Set<Segment>) -> Digit? {
    switch segments {
    case [.a, .b, .c, .e, .f, .g]:
      return .zero
    case [.c, .f]:
      return .one
    case [.a, .c, .d, .e, .g]:
      return .two
    case [.a, .c, .d, .f, .g]:
      return .three
    case [.b, .c, .d, .f]:
      return .four
    case [.a, .b, .d, .f, .g]:
      return .five
    case [.a, .b, .d, .e, .f, .g]:
      return .six
    case [.a, .c, .f]:
      return .seven
    case [.a, .b, .c, .d, .e, .f, .g]:
      return .eight
    case [.a, .b, .c, .d, .f, .g]:
      return .nine
    default:
      return nil
    }
  }
}

struct BrokenDigit: Hashable {
  let segments: Set<Segment>

  func toDigit(map: SegmentMap) -> Digit? {
    .from(Set(segments.compactMap { map.map[$0] }))
  }
}

struct SegmentMap {
  var map: [Segment: Segment]

  static func allPossibleMaps() -> [SegmentMap] {
    Segment.allCases.uniquePermutations().map { permutation in
      SegmentMap(
        map: Dictionary(
          uniqueKeysWithValues: zip(Segment.allCases, permutation)
        )
      )
    }
  }
}

struct Line {
  let input: [BrokenDigit]
  let output: [BrokenDigit]

  init(input: [BrokenDigit], output: [BrokenDigit]) {
    self.input = input.filter { !$0.segments.isEmpty }
    self.output = output.filter { !$0.segments.isEmpty }
  }

  func generateSegmentMap() -> SegmentMap? {
    let brokenDigitsToGuess = Set(input + output)
    let allPossibleMaps = SegmentMap.allPossibleMaps()
    return allPossibleMaps.first { map in
      return brokenDigitsToGuess.allSatisfy { $0.toDigit(map: map) != nil }
    }
  }
}

// MARK: - Parsers

let segment = OneOfMany(
  "a".map { Segment.a },
  "b".map { .b },
  "c".map { .c },
  "d".map { .d },
  "e".map { .e },
  "f".map { .f },
  "g".map { .g }
)

let digit = Many(segment)
  .map(Set.init)
  .map(BrokenDigit.init)

let digits = Many(digit, separator: " ")

let line = digits
  .skip("|")
  .take(digits)
  .map(Line.init)

let lines = Many(line, separator: "\n")

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let parsedInput = lines.parse(&input)!

let correctedOutput = parsedInput
  .compactMap { line -> [Digit]? in
    guard let segmentMap = line.generateSegmentMap() else { return nil }
    return line.output.compactMap { $0.toDigit(map: segmentMap) }
  }

// MARK: - Parts 1 & 2

func partOne() -> Int {
  correctedOutput
    .reduce(0) { count, digits in
      count + digits.filter({ [.one, .four, .seven, .eight].contains($0) }).count
    }
}

func partTwo() -> Int {
  correctedOutput
    .reduce(0) { sum, digits in
      sum + digits.reduce(0) { ($0 * 10) + $1.rawValue }
    }
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
