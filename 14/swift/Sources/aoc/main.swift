import Algorithms
import Foundation
import Parsing

// MARK: - Models

struct TemplatePair: Hashable {
  let first: Character
  let second: Character
  let atStart: Bool
  let atEnd: Bool

  var onEdge: Bool { atStart || atEnd }
}

struct Template {
  var pairs: [TemplatePair: Int]

  init(string: Substring) {
    let characterPairs = Array(string.adjacentPairs().enumerated())
    pairs = characterPairs
      .map { index, pair in
        TemplatePair(
          first: pair.0,
          second: pair.1,
          atStart: index == 0,
          atEnd: index == characterPairs.indices.last
        )
      }
      .reduce(into: [:]) { $0[$1, default: 0] += 1 }
  }

  mutating func advance(rules: InsertionRules) {
    pairs = pairs
      .reduce(into: [:]) { newPairs, pairWithCount in
        let (pair, count) = pairWithCount
        guard let insertion = rules.output(for: pair) else {
          newPairs[pair, default: 0] += count
          return
        }

        let starting = TemplatePair(first: pair.first, second: insertion, atStart: pair.atStart, atEnd: false)
        newPairs[starting, default: 0] += count
        let ending = TemplatePair(first: insertion, second: pair.second, atStart: false, atEnd: pair.atEnd)
        newPairs[ending, default: 0] += count
      }
  }

  func score() -> Int {
    var counts = [Character: Int]()
    for (pair, count) in pairs where !pair.onEdge {
      counts[pair.first, default: 0] += count
      counts[pair.second, default: 0] += count
    }

    // middle values are double counted because adjacent pairs overlap
    counts = counts.mapValues { $0 / 2 }

    for (pair, count) in pairs where pair.onEdge {
      counts[pair.first, default: 0] += count
      counts[pair.second, default: 0] += count
    }

    return counts.values.max()! - counts.values.min()!
  }
}

struct CharacterPair: Hashable {
  let first: Character
  let second: Character
}

struct InsertionRule {
  let input: CharacterPair
  let output: Character
}

struct InsertionRules {
  let map: [CharacterPair: Character]
  init(rules: [InsertionRule]) {
    map = Dictionary(
      uniqueKeysWithValues: rules.map { ($0.input, $0.output) }
    )
  }

  func output(for pair: TemplatePair) -> Character? {
    map[CharacterPair(first: pair.first, second: pair.second)]
  }
}

// MARK: - Parsers

extension Template {
  static func parser() -> AnyParser<Substring, Template> {
    PrefixUpTo("\n")
      .map(Template.init)
      .eraseToAnyParser()
  }
}

extension CharacterPair {
  static func parser() -> AnyParser<Substring, CharacterPair> {
    Prefix(2)
      .map { CharacterPair(first: $0.first!, second: $0.last!) }
      .eraseToAnyParser()
  }
}

extension InsertionRule {
  static func parser() -> AnyParser<Substring, InsertionRule> {
    CharacterPair.parser()
      .skip(" -> ")
      .take(Prefix(1).map(\.first!))
      .map(InsertionRule.init)
      .eraseToAnyParser()
  }
}

extension InsertionRules {
  static func parser() -> AnyParser<Substring, InsertionRules> {
    Many(InsertionRule.parser(), separator: "\n")
      .map(InsertionRules.init)
      .eraseToAnyParser()
  }
}

let lines = Template.parser()
  .skip("\n\n")
  .take(InsertionRules.parser())

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let (template, rules) = lines.parse(&input)!

// MARK: - Parts 1 & 2

func scoreAfter(steps: Int) -> Int {
  (1...steps)
    .reduce(into: template) { template, _ in
      template.advance(rules: rules)
    }
    .score()
}

func partOne() -> Int {
  scoreAfter(steps: 10)
}

func partTwo() -> Int {
  scoreAfter(steps: 40)
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
