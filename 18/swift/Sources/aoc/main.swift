import Algorithms
import Dispatch
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
}

// MARK: - Models

indirect enum PairElement: Hashable {
  case number(Int)
  case pair(Pair)

  var isNumber: Bool {
    switch self {
    case .number:
      return true
    case .pair:
      return false
    }
  }

  var isPair: Bool {
    switch self {
    case .number:
      return false
    case .pair:
      return true
    }
  }

  var number: Int? {
    switch self {
    case .number(let value):
      return value
    case .pair:
      return nil
    }
  }

  var pair: Pair? {
    switch self {
    case .number:
      return nil
    case .pair(let pair):
      return pair
    }
  }

  func magnitude() -> Int {
    switch self {
    case .number(let int):
      return int
    case .pair(let pair):
      return pair.magnitude()
    }
  }
}

struct Pair: Hashable {
  var left: PairElement
  var right: PairElement
  let sortedPairElementsCache = SortedPairElementsCache()

  enum Side: Comparable, Hashable, CaseIterable {
    case left, right

    func toggled() -> Side {
      switch self {
      case .left:
        return .right
      case .right:
        return .left
      }
    }
  }

  struct Index: Comparable, Hashable {
    static func < (lhs: Index, rhs: Index) -> Bool {
      for (lhsBreadcrumb, rhsBreadcrumb) in zip(lhs.breadcrumbs, rhs.breadcrumbs) {
        if lhsBreadcrumb < rhsBreadcrumb {
          return true
        } else if lhsBreadcrumb > rhsBreadcrumb {
          return false
        }
      }

      return lhs.breadcrumbs.count < rhs.breadcrumbs.count
    }

    let breadcrumbs: [Side]

    static func + (lhs: Index, rhs: [Side]) -> Index {
      Index(breadcrumbs: lhs.breadcrumbs + rhs)
    }

    static func + (lhs: Index, rhs: Index) -> Index {
      lhs + rhs.breadcrumbs
    }
  }

  struct IndexAndPairElement: Comparable, Hashable {
    let index: Index
    let element: PairElement

    static func == (lhs: IndexAndPairElement, rhs: IndexAndPairElement) -> Bool {
      lhs.index == rhs.index
    }

    static func < (lhs: IndexAndPairElement, rhs: IndexAndPairElement) -> Bool {
      lhs.index < rhs.index
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(index)
    }
  }

  final class SortedPairElementsCache: Hashable {
    var elements = [IndexAndPairElement]()
    init() {}

    static func == (lhs: SortedPairElementsCache, rhs: SortedPairElementsCache) -> Bool {
      true
    }

    func hash(into hasher: inout Hasher) {}
  }

  func clearCache() {
    sortedPairElementsCache.elements = []
  }

  func sortedPairElements() -> [IndexAndPairElement] {
    guard sortedPairElementsCache.elements.isEmpty else {
      return sortedPairElementsCache.elements
    }

    var pairsToCheck: [IndexAndPairElement] = [
      .init(index: Index(breadcrumbs: [.left]), element: left),
      .init(index: Index(breadcrumbs: [.right]), element: right),
    ]
    var result = Set(pairsToCheck)

    while !pairsToCheck.isEmpty {
      result.formUnion(pairsToCheck)
      pairsToCheck = pairsToCheck.flatMap { indexAndPairElement -> [IndexAndPairElement] in
        guard let pair = indexAndPairElement.element.pair else { return [] }

        return Side.allCases.map { side in
          .init(
            index: indexAndPairElement.index + [side],
            element: pair.element(onThe: side)
          )
        }
      }
    }

    sortedPairElementsCache.elements = result.sorted()
    return sortedPairElementsCache.elements
  }

  func first(where predicate: (IndexAndPairElement) -> Bool) -> IndexAndPairElement? {
    sortedPairElements()
      .first(where: predicate)
  }

  func element(onThe side: Side) -> PairElement {
    switch side {
    case .left:
      return left
    case .right:
      return right
    }
  }

  func furthestElement(onThe side: Side) -> IndexAndPairElement {
    let element = element(onThe: side)
    switch element {
    case .number:
      return .init(index: Index(breadcrumbs: [side]), element: element)
    case .pair(let pair):
      let nextFurthest = pair.furthestElement(onThe: side)
      return .init(
        index: nextFurthest.index + [side],
        element: nextFurthest.element
      )
    }
  }

  func firstNumber(toThe side: Side, of index: Index) -> IndexAndPairElement? {
    if index.breadcrumbs.allSatisfy({ $0 == side }) { return nil }

    var parentBreadcrumbs = Array(index.breadcrumbs.reversed().drop(while: { $0 == side }))
    parentBreadcrumbs[0] = parentBreadcrumbs.first!.toggled()
    parentBreadcrumbs = parentBreadcrumbs.reversed()
    let parentIndex = Index(breadcrumbs: parentBreadcrumbs)
    let parentElement = element(at: parentIndex)

    switch parentElement {
    case .number:
      return .init(index: parentIndex, element: parentElement)
    case .pair(let parentPair):
      let parentFurthestElement = parentPair.furthestElement(onThe: side.toggled())
      return .init(
        index: parentIndex + parentFurthestElement.index,
        element: parentFurthestElement.element
      )
    }
  }

  func element(at index: Index) -> PairElement {
    var nextElement: PairElement = .pair(self)
    for side in index.breadcrumbs {
      switch nextElement {
      case .number:
        return nextElement
      case .pair(let pair):
        nextElement = pair.element(onThe: side)
      }
    }

    return nextElement
  }

  mutating func set(element: PairElement, at index: Index) {
    clearCache()
    if index.breadcrumbs.count == 1 {
      switch index.breadcrumbs[0] {
      case .left:
        left = element
      case .right:
        right = element
      }
      return
    }

    var shrinkingBreadcrumbs = index.breadcrumbs
    var builder = self.element(at: .init(breadcrumbs: shrinkingBreadcrumbs.dropLast())).pair!
    builder.set(element: element, at: .init(breadcrumbs: [shrinkingBreadcrumbs.popLast()!]))
    while let lastBreadcrumb = shrinkingBreadcrumbs.popLast() {
      let pair = self.element(at: .init(breadcrumbs: shrinkingBreadcrumbs)).pair!
      builder = Pair(
        left: lastBreadcrumb == .left ? .pair(builder) : pair.left,
        right: lastBreadcrumb == .right ? .pair(builder) : pair.right
      )
    }

    self = builder
  }

  mutating func explode() -> Bool {
    guard let exploding = first(where: { $0.element.isPair && $0.index.breadcrumbs.count >= 4 }) else {
      return false
    }

    let explodingPair = exploding.element.pair!
    for side in Side.allCases {
      if let numberToExplodeInto = firstNumber(toThe: side, of: exploding.index) {
        let numberValueToExplodeInto = numberToExplodeInto.element.number!
        let explodingNumber = explodingPair.element(onThe: side).number!
        let explodingSum = numberValueToExplodeInto + explodingNumber
        set(element: .number(explodingSum), at: numberToExplodeInto.index)
      }
    }

    set(element: .number(0), at: exploding.index)
    return true
  }

  mutating func split() -> Bool {
    guard let number = first(where: { $0.element.isNumber && $0.element.number! >= 10 }) else {
      return false
    }

    let numberBeforeSplit = number.element.number!
    let numberDividedByTwo = Double(numberBeforeSplit) / 2
    let left = Int(numberDividedByTwo.rounded(.down))
    let right = Int(numberDividedByTwo.rounded(.up))

    set(element: .pair(Pair(left: .number(left), right: .number(right))), at: number.index)
    return true
  }

  func adding(_ other: Pair) -> Pair {
    var result = Pair(left: .pair(self), right: .pair(other))
    while result.explode() || result.split() {}
    return result
  }

  func magnitude() -> Int {
    (left.magnitude() * 3) + (right.magnitude() * 2)
  }
}

extension Collection where Element == Pair {
  func adding() -> Pair {
    self
      .dropFirst()
      .reduce(self.first!) { $0.adding($1) }
  }

  func magnitudeAfterAdding() -> Int {
    adding().magnitude()
  }

  func largestTwoAddMagnitude() -> Int {
    permutations(ofCount: 2)
      .map { $0 }
      .parallelMap { $0.magnitudeAfterAdding() }
      .max()!
  }
}

// MARK: - Parsers

func makePairParser<E: Parser>(elementParser: E) -> AnyParser<Substring, Pair>
  where E.Input == Substring, E.Output == PairElement
{
  Skip("[")
    .take(elementParser)
    .skip(",")
    .take(elementParser)
    .skip("]")
    .map(Pair.init)
    .eraseToAnyParser()
}

let pairElementNumber = Int.parser()
  .map(PairElement.number)
let pairOfNumbers = makePairParser(elementParser: pairElementNumber)
// Only pairs up to a nesting level of 4 are supported. Increase this value if needed.
let pairParsers = (0..<4).reduce(into: [pairOfNumbers]) { parsers, _ in
  parsers.append(
    makePairParser(
      elementParser: parsers
        .reduce(Fail().eraseToAnyParser()) { $0.orElse($1).eraseToAnyParser() }
        .map(PairElement.pair)
        .orElse(pairElementNumber)
    )
  )
}

let pairElement = pairParsers.reduce(pairElementNumber.eraseToAnyParser()) { result, pairParser in
  result
    .orElse(pairParser.map(PairElement.pair))
    .eraseToAnyParser()
}

let pair = makePairParser(elementParser: pairElement.eraseToAnyParser())

let parser = Many(pair, separator: "\n")

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let pairs = parser.parse(&input)!

// MARK: - Parts 1 & 2

func partOne() -> Int {
  pairs.magnitudeAfterAdding()
}

func partTwo() -> Int {
  pairs.largestTwoAddMagnitude()
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
