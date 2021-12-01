import Foundation

extension Sequence where Element: Comparable {
  var increases: Int {
    zip(self.dropFirst(), self)
      .filter(>)
      .count
  }
}

// MARK: - Part 1

print("# Part 1")

let contents = try String(contentsOfFile: "input.txt", encoding: .utf8)
let lines = contents.components(separatedBy: .newlines)
let numbers = lines.compactMap(Int.init)
let increases = numbers.increases
print("Increases: \(increases)")

// MARK: - Part 2

print("# Part 2")

struct Window {
  let members: [Int]
  var sum: Int { members.reduce(0, +) }
}

let windowsOfThree = zip(zip(numbers, numbers.dropFirst()), numbers.dropFirst().dropFirst())
  .map { Window(members: [$0.0, $0.1, $1]) }
let windowsOfThreeIncreases = windowsOfThree.map(\.sum).increases
print("Windows of 3 increases: \(windowsOfThreeIncreases)")
