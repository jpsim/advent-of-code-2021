import Foundation

// MARK: - Most Common Bit

extension Collection where Element == Bool {
  func mostCommonBit() -> Bool {
    let trueCount = filter({ $0 }).count
    let falseCount = count - trueCount
    return trueCount >= falseCount
  }
}

// MARK: Bits To Int

extension UInt {
  init(bits: [Bool]) {
    self = bits.reduce(into: 0) { result, bit in
      result = result << 1
      result += bit ? 1 : 0
    }
  }
}

// MARK: Most Common Bit At Index

extension Collection where Element == [Bool] {
  func mostCommonBit(atIndex index: Int) -> Bool {
    self
      .map { $0[index] }
      .mostCommonBit()
  }
}

// MARK: - Get Gamma

func getGamma() -> UInt {
  return UInt(bits: (0..<bits[0].count).map { index in
    bits.mostCommonBit(atIndex: index)
  })
}

// MARK: - Get Epsilon

func getEpsilon() -> UInt {
  return UInt(bits: (0..<bits[0].count).map { index in
    !bits.mostCommonBit(atIndex: index)
  })
}

// MARK: - Get Oxygen Generator Rating

func getOxygenGeneratorRating() -> UInt {
  let numberOfBits = bits[0].count
  var shrinkingBits = bits
  for bitIndex in 0..<numberOfBits {
    let mostCommonBit = shrinkingBits
      .mostCommonBit(atIndex: bitIndex)
    shrinkingBits.removeAll { $0[bitIndex] != mostCommonBit }
    if shrinkingBits.count == 1 { break }
  }

  return UInt(bits: shrinkingBits[0])
}

// MARK: - Get CO2 Scrubber Rating

func getCO2ScrubberRating() -> UInt {
  let numberOfBits = bits[0].count
  var shrinkingBits = bits
  for bitIndex in 0..<numberOfBits {
    let leastCommonBit = !shrinkingBits
      .mostCommonBit(atIndex: bitIndex)
    shrinkingBits.removeAll { $0[bitIndex] != leastCommonBit }
    if shrinkingBits.count == 1 { break }
  }

  return UInt(bits: shrinkingBits[0])
}

// MARK: - Read Input

let contents = try String(contentsOfFile: "input.txt", encoding: .utf8)
let lines = contents.components(separatedBy: .newlines)
let bits = lines
  .map { $0.map { $0 == "1" ? true : false } }
  .dropLast()

// MARK: - Part 1

print("# Part 1")
let gamma = getGamma()
print("gamma: \(gamma)")
let epsilon = getEpsilon()
print("epsilon: \(epsilon)")
let powerConsumption = gamma * epsilon
print("power consumption: \(powerConsumption)")

// MARK: - Part 2

print("# Part 2")
let oxygenGeneratorRating = getOxygenGeneratorRating()
print("oxygen generator rating: \(oxygenGeneratorRating)")
let co2ScrubberRating = getCO2ScrubberRating()
print("CO2 scrubber rating: \(co2ScrubberRating)")
let lifeSupportRating = oxygenGeneratorRating * co2ScrubberRating
print("life support rating: \(lifeSupportRating)")
