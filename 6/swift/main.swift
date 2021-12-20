import Foundation

let contents = try String(contentsOfFile: "input.txt", encoding: .utf8)
let lines = contents.components(separatedBy: .newlines)
let initialState = lines[0]
    .split(separator: ",")
    .compactMap { Int($0) }

var cachedCountAtAgeZeroForDay = [Int: Int]()

func fishCount(age: Int, afterDays days: Int) -> Int {
  guard days > age else { return 1 }
  guard age == 0 else { return fishCount(age: 0, afterDays: days - age) }

  if let existing = cachedCountAtAgeZeroForDay[days] {
    return existing
  }

  let count = fishCount(age: 7, afterDays: days) + fishCount(age: 9, afterDays: days)
  cachedCountAtAgeZeroForDay[days] = count
  return count
}

func fish(afterDays days: Int, initialState: [Int]) -> Int {
  initialState
    .map { fishCount(age: $0, afterDays: days) }
    .reduce(0, +)
}

func printFish(afterDays days: Int, initialState: [Int]) {
  let fishCount = fish(afterDays: days, initialState: initialState)
  print("\(fishCount) lantern fish after \(days) days")
}

printFish(afterDays: 80, initialState: initialState)
printFish(afterDays: 256, initialState: initialState)
