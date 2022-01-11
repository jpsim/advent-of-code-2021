import Foundation
import Parsing

// MARK: - Models

enum Variable {
  case w, x, y, z
}

enum VariableOrNumber {
  case variable(Variable)
  case number(Int)
}

enum Instruction {
  case inp(a: Variable)
  case add(a: Variable, b: VariableOrNumber)
  case mul(a: Variable, b: VariableOrNumber)
  case div(a: Variable, b: VariableOrNumber)
  case mod(a: Variable, b: VariableOrNumber)
  case eql(a: Variable, b: VariableOrNumber)
}

struct ModelNumbers {
  let smallest: Int
  let largest: Int
}

// MARK: - Computation

struct ALU {
  var w = 0
  var x = 0
  var y = 0
  var z = 0

  subscript(variable: Variable) -> Int {
    get {
      switch variable {
      case .w: return w
      case .x: return x
      case .y: return y
      case .z: return z
      }
    }

    set {
      switch variable {
      case .w: w = newValue
      case .x: x = newValue
      case .y: y = newValue
      case .z: z = newValue
      }
    }
  }

  subscript(variableOrNumber: VariableOrNumber) -> Int {
    switch variableOrNumber {
    case .variable(let variable):
      return self[variable]
    case .number(let int):
      return int
    }
  }

  mutating func process(inputs: [Int], instructions: [Instruction]) {
    var mutableInputs = inputs[...]
    for instruction in instructions {
      switch instruction {
      case .inp(let a):
        self[a] = mutableInputs.popFirst()!
      case .add(let a, let b):
        self[a] += self[b]
      case .mul(let a, let b):
        self[a] *= self[b]
      case .div(let a, let b):
        self[a] /= self[b]
      case .mod(let a, let b):
        self[a] %= self[b]
      case .eql(let a, let b):
        self[a] = (self[a] == self[b]) ? 1 : 0
      }
    }
  }
}

extension Int {
  func digits() -> [Int] {
    var copy = self
    var result = [Int]()
    while copy > 0 {
      result.append(copy % 10)
      copy /= 10
    }
    return result.reversed()
  }
}

extension Array where Element == Int {
  func toInteger() -> Int {
    reduce(0) { result, digit in
      (result * 10) + digit
    }
  }
}

/// Generates the smallest and largest valid model numbers through the MONAD program.
/// It's possible to run each candidate input number through the ALU procedurally, and in fact that was my
/// first attempt at solving this problem, but I could only get up to 330M attempts per minute, which would
/// take over 200 days to exhaust the search space of 14 digit decimal numbers without zeroes.
/// Instead this generator derives the smallest and largest possible values to satisfy the validity
/// requirement of `z` being `0` after processing a number, which was derived by staring at the instructions
/// and noticing that the validity requirement depends entirely on the number being added to `y` 11
/// instructions after a division of `z` by `1` (`Divisions.by1`) and the number being added to `x` 1
/// instruction after a division of `z` by `26` (`Divisions.by26`).
enum ModelNumbersGenerator {
  static func generateModelNumbers(from instructions: [Instruction]) -> ModelNumbers {
    getModelNumbers(divisions: getDivisions(instructions: instructions))
  }

  private struct Divisions {
    /// Additions to `y` after dividing `z` by 1
    var by1: [Int?]
    /// Additions to `x` after dividing `z` by 26
    var by26: [Int?]

    func zipped() -> [(index: Int, by1: Int?, by26: Int?)] {
      zip(by1, by26)
        .enumerated()
        .map { ($0, $1.0, $1.1) }
    }
  }

  private static func getDivisions(instructions: [Instruction]) -> Divisions {
    stride(from: 0, to: instructions.count, by: 18) // Instructions are in groups of 18 starting with `inp w`
      .reduce(into: Divisions(by1: [], by26: [])) { divisions, instructionIndex in
        switch instructions[instructionIndex + 4] { // Divisions of `z` are the 4th instruction after `inp w`
        case .div(a: .z, b: .number(1)): // `div z 1`
          if case .add(a: .y, b: .number(let b)) = instructions[instructionIndex + 15] { // `add y <b>`
            divisions.by1.append(b)
          }
          divisions.by26.append(nil)
        case .div(a: .z, b: .number(26)): // `div z 26`
          if case .add(a: .x, b: .number(let b)) = instructions[instructionIndex + 5] { // `add x <b>`
            divisions.by26.append(b)
          }
          divisions.by1.append(nil)
        default:
          break
        }
      }
  }

  private static func getModelNumbers(divisions: Divisions) -> ModelNumbers {
    var smallest = Array(repeating: 0, count: 14)
    var largest = Array(repeating: 0, count: 14)
    var stack = [(index: Int, divisionBy1: Int)]()

    for (divisionIndex, divisionBy1, divisionBy26) in divisions.zipped() {
      if let divisionBy1 = divisionBy1 {
        stack.append((divisionIndex, divisionBy1))
      } else if let divisionBy26 = divisionBy26, let (divisionBy1Index, divisionBy1) = stack.popLast() {
        let diff = divisionBy1 + divisionBy26
        smallest[divisionBy1Index] = max(1, 1 - diff)
        smallest[divisionIndex] = max(1, 1 + diff)
        largest[divisionBy1Index] = min(9, 9 - diff)
        largest[divisionIndex] = min(9, 9 + diff)
      }
    }

    return ModelNumbers(smallest: smallest.toInteger(), largest: largest.toInteger())
  }
}

// MARK: - Parsers

let variable = OneOfMany(
  "w".map { Variable.w },
  "x".map { .x },
  "y".map { .y },
  "z".map { .z }
)

let variableOrNumber = variable.map(VariableOrNumber.variable)
  .orElse(Int.parser().map(VariableOrNumber.number))

let instruction = "inp ".take(variable).map(Instruction.inp)
          .orElse("add ".take(variable).skip(" ").take(variableOrNumber).map(Instruction.add))
          .orElse("mul ".take(variable).skip(" ").take(variableOrNumber).map(Instruction.mul))
          .orElse("div ".take(variable).skip(" ").take(variableOrNumber).map(Instruction.div))
          .orElse("mod ".take(variable).skip(" ").take(variableOrNumber).map(Instruction.mod))
          .orElse("eql ".take(variable).skip(" ").take(variableOrNumber).map(Instruction.eql))

let parser = Many(instruction, atLeast: 1, separator: "\n")

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let instructions = parser.parse(&input)!

// MARK: - Parts 1 & 2

let modelNumbers = ModelNumbersGenerator.generateModelNumbers(from: instructions)

do { // validate that the smallest model number passes procedural ALU validation
  var alu = ALU()
  alu.process(inputs: modelNumbers.smallest.digits(), instructions: instructions)
  precondition(alu.z == 0)
}

do { // validate that the largest model number passes procedural ALU validation
  var alu = ALU()
  alu.process(inputs: modelNumbers.largest.digits(), instructions: instructions)
  precondition(alu.z == 0)
}

print("Part 1:", modelNumbers.largest)
print("Part 2:", modelNumbers.smallest)
