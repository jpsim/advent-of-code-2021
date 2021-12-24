import Foundation
import Parsing

// MARK: - Models

struct LiteralPacket {
  let version: Int
  let value: Int
}

enum OperatorType: Int {
  case sum = 0
  case product = 1
  case minimum = 2
  case maximum = 3
  case greater = 5
  case less = 6
  case equal = 7
}

struct OperatorPacket {
  let version: Int
  let type: OperatorType
  let contents: OperatorPacketContents

  var value: Int {
    let packets = contents.packets
    switch type {
    case .sum:
      return packets.map(\.value).reduce(0, +)
    case .product:
      return packets.map(\.value).reduce(1, *)
    case .minimum:
      return packets.map(\.value).min()!
    case .maximum:
      return packets.map(\.value).max()!
    case .greater:
      return (packets[0].value > packets[1].value) ? 1 : 0
    case .less:
      return (packets[0].value < packets[1].value) ? 1 : 0
    case .equal:
      return (packets[0].value == packets[1].value) ? 1 : 0
    }
  }

  var versionSum: Int {
    version + contents.versionSum
  }
}

enum OperatorPacketHeader {
  case lengthOfSubPacketsInBits(Int)
  case numberOfSubPackets(Int)
}

struct OperatorPacketContents {
  let packets: [Packet]

  var versionSum: Int {
    packets
      .map(\.versionSum)
      .reduce(0, +)
  }
}

enum Packet {
  case literal(LiteralPacket)
  case op(OperatorPacket)

  var value: Int {
    switch self {
    case .literal(let literalPacket):
      return literalPacket.value
    case .op(let operatorPacket):
      return operatorPacket.value
    }
  }

  var versionSum: Int {
    switch self {
    case .literal(let literalPacket):
      return literalPacket.version
    case .op(let operatorPacket):
      return operatorPacket.versionSum
    }
  }
}

// MARK: - Parsers

typealias ParserInput = Array<Bool>.SubSequence

let hexMap: [Character: [Bool]] = [
  "0": [false, false, false, false],
  "1": [false, false, false, true],
  "2": [false, false, true, false],
  "3": [false, false, true, true],
  "4": [false, true, false, false],
  "5": [false, true, false, true],
  "6": [false, true, true, false],
  "7": [false, true, true, true],
  "8": [true, false, false, false],
  "9": [true, false, false, true],
  "A": [true, false, true, false],
  "B": [true, false, true, true],
  "C": [true, true, false, false],
  "D": [true, true, false, true],
  "E": [true, true, true, false],
  "F": [true, true, true, true],
]

extension String {
  func convertToBinarySubsequence() -> ParserInput {
    self
      .compactMap { hexMap[$0] }
      .joined()
      .reduce(into: [], { $0.append($1) })[...]
  }
}

extension OperatorPacketContents {
  static func parser(from header: OperatorPacketHeader) -> AnyParser<ParserInput, OperatorPacketContents> {
    switch header {
    case .lengthOfSubPacketsInBits(let int):
      return Prefix(int)
        .pipe(Many(packet))
        .map(OperatorPacketContents.init)
        .eraseToAnyParser()
    case .numberOfSubPackets(let int):
      return Many(packet, atLeast: int, atMost: int)
        .map(OperatorPacketContents.init)
        .eraseToAnyParser()
    }
  }
}

let bit = Prefix<ParserInput>(1)
  .map { $0 == [true][...] }

let binaryInt = Many(bit)
  .map { bits in
    bits.reduce(0) { int, bit -> Int in
      (int << 1) + (bit ? 1 : 0)
    }
  }

let threeBitInt = Prefix(3)
  .pipe(binaryInt)

let literalPacketContents = Prefix(1)
  .flatMap { isLastFourBitGroup -> AnyParser<ParserInput, [ParserInput]> in
    let fourBits = Prefix<ParserInput>(4)
    if isLastFourBitGroup.first! {
      return Many(
        fourBits,
        separator: [true]
      )
      .take(
        Skip([false])
          .take(
            fourBits.map { [$0] }
          )
      )
      .map(+)
      .eraseToAnyParser()
    } else {
      return fourBits
        .map { [$0] }
        .eraseToAnyParser()
    }
  }
  .map { input in input.flatMap({ $0 })[...] }
  .pipe(binaryInt)

let literalPacket = threeBitInt
  .skip(StartsWith([true, false, false]))
  .take(literalPacketContents)
  .map(LiteralPacket.init)

let operatorPacketHeader = Skip(StartsWith<ParserInput>([false]))
  .take(
    Prefix(15)
      .pipe(binaryInt)
  )
  .map(OperatorPacketHeader.lengthOfSubPacketsInBits)
  .orElse(
    Skip(StartsWith<ParserInput>([true]))
      .take(
        Prefix(11)
          .pipe(binaryInt)
      )
      .map(OperatorPacketHeader.numberOfSubPackets)
  )

let operatorType = threeBitInt
  .compactMap(OperatorType.init)

let operatorPacket = threeBitInt
  .take(operatorType)
  .take(
    operatorPacketHeader
      .flatMap(OperatorPacketContents.parser(from:))
  )
  .map(OperatorPacket.init)

let packet = literalPacket
  .map(Packet.literal)
  .orElse(
    operatorPacket
      .map(Packet.op)
  )

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)
  .convertToBinarySubsequence()
let parsedPacket = packet.parse(&input)!

// MARK: - Parts 1 & 2

func partOne() -> Int {
  parsedPacket.versionSum
}

func partTwo() -> Int {
  parsedPacket.value
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
