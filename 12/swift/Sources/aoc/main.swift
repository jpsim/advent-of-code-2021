import Algorithms
import Dispatch
import Foundation
import Parsing

// MARK: - Parallel Processing

extension Array {
  func parallelMap<T>(transform: (Element) -> T) -> [T] {
    return [T](unsafeUninitializedCapacity: count) { buffer, initializedCount in
      let baseAddress = buffer.baseAddress!
      DispatchQueue.concurrentPerform(iterations: count) { index in
        (baseAddress + index).initialize(to: transform(self[index]))
      }
      initializedCount = count
    }
  }

  func parallelFlatMap<T>(transform: (Element) -> [T]) -> [T] {
    return parallelMap(transform: transform).flatMap { $0 }
  }
}

// MARK: - ID Factory

final class CaveIDFactory {
  typealias ID = UInt8
  private var mapping = [Substring: ID]()
  private var nextID: ID = 2

  static let shared = CaveIDFactory()

  func id(forName name: Substring) -> ID {
    if let cached = mapping[name] {
      return cached
    } else if name == "start" {
      return 0
    } else if name == "end" {
      return 1
    } else {
      nextID += 1
      mapping[name] = nextID
      return nextID
    }
  }
}

// MARK: - Models

enum Part {
  case part1, part2
}

struct Cave: Hashable {
  let id: UInt8
  let isSmall: Bool

  init?(name: Substring) {
    guard let first = name.first else { return nil }
    self.id = CaveIDFactory.shared.id(forName: name)
    self.isSmall = first.isLowercase
  }

  static let start = Cave(name: "start")!
  static let end = Cave(name: "end")!
}

struct Segment {
  let cave1: Cave
  let cave2: Cave

  func contains(_ cave: Cave) -> Bool {
    cave == cave1 || cave == cave2
  }

  func other(than cave: Cave) -> Cave {
    cave == cave1 ? cave2 : cave1
  }
}

struct Path: Hashable {
  let caves: [Cave]

  func isValid(for part: Part) -> Bool {
    var visitedCaves = Set<Cave>()
    var didVisitSmallCaveTwice = false
    for cave in caves where cave.isSmall {
      if !visitedCaves.contains(cave) {
        visitedCaves.insert(cave)
      } else if part == .part1 {
        return false
      } else if didVisitSmallCaveTwice {
        return false
      } else if cave == .start || cave == .end {
        return false
      } else {
        didVisitSmallCaveTwice = true
      }
    }

    return true
  }

  func generateMore(map: Map, for part: Part) -> [Path] {
    map.cavesAccessible(from: caves.last!)
      .map { Path(caves: caves + [$0]) }
      .filter { $0.isValid(for: part) }
  }

  var reachesEnd: Bool {
    caves.last == .end
  }
}

struct Map {
  let segments: [Segment]

  func cavesAccessible(from cave: Cave) -> [Cave] {
    segments
      .filter { $0.contains(cave) }
      .map { $0.other(than: cave) }
  }

  func completePaths(for part: Part) -> Int {
    var possiblePaths = cavesAccessible(from: .start)
      .map { Path(caves: [.start, $0]) }
    var completePaths = Set<Path>()
    while !possiblePaths.isEmpty {
      let newPossiblePaths = Set(
        possiblePaths
          .parallelFlatMap { $0.generateMore(map: self, for: part) }
      )
      .subtracting(completePaths)
      completePaths.formUnion(newPossiblePaths.filter(\.reachesEnd))
      possiblePaths = newPossiblePaths.filter({ !$0.reachesEnd })
    }

    return completePaths.count
  }
}

// MARK: - Parsers

let cave = Prefix<Substring> { $0 != "-" && $0 != "\n" }
  .compactMap(Cave.init)

let segment = cave
  .skip("-")
  .take(cave)
  .map(Segment.init)
let segments = Many(segment, separator: "\n")
let map = segments
  .map(Map.init)

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let parsedInput = map.parse(&input)!

// MARK: - Parts 1 & 2

func partOne() -> Int {
  parsedInput.completePaths(for: .part1)
}

func partTwo() -> Int {
  parsedInput.completePaths(for: .part2)
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
