import Foundation

let contents = try String(contentsOfFile: "input.txt", encoding: .utf8)
let lines = contents.components(separatedBy: .newlines)
let initialState = lines[0]
    .split(separator: ",")
    .compactMap { Int($0) }

extension Array where Element == Int {
  func median() -> Int {
    sorted()[count / 2]
  }

  func partOneCost(to destination: Int) -> Int {
    self
      .map { abs($0 - destination) }
      .reduce(0, +)
  }

  func partTwoCost(to destination: Int) -> Int {
    self
      .map { abs($0 - destination) }
      .map { (0...$0).reduce(0, +) }
      .reduce(0, +)
  }
}

func partOne() -> Int {
  initialState.partOneCost(to: initialState.median())
}

func partTwo() -> Int {
  (initialState.min()! ... initialState.max()!)
    .map(initialState.partTwoCost(to:))
    .min()!
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
