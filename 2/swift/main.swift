import Foundation

enum RawCommand: String, CaseIterable {
  case forward, down, up
}

struct Command {
  let rawCommand: RawCommand
  let amount: Int

  init?(_ rawValue: String) {
    for command in RawCommand.allCases {
      let prefix = "\(command.rawValue) "
      if rawValue.hasPrefix(prefix) {
        rawCommand = command
        let stringAmount = rawValue.dropFirst(prefix.count)
        if let intAmount = Int(stringAmount) {
          amount = intAmount
          return
        } else {
          return nil
        }
      }
    }

    return nil
  }

  var position: Int {
    switch rawCommand {
    case .forward:
      return amount
    case .down, .up:
      return 0
    }
  }

  var depth: Int {
    switch rawCommand {
    case .forward:
      return 0
    case .down:
      return amount
    case .up:
      return -amount
    }
  }
}

let contents = try String(contentsOfFile: "input.txt", encoding: .utf8)
let lines = contents.components(separatedBy: .newlines)
let commands = lines.compactMap(Command.init)

// MARK: - Part 1

print("# Part 1")

do {
  let (position, depth) = commands.reduce(into: (0, 0)) { result, command in
    result.0 += command.position
    result.1 += command.depth
  }

  print("Position: \(position)")
  print("Depth: \(depth)")
  print("Multiplied: \(position * depth)")
}

// MARK: - Part 2

print("# Part 2")

do {
  var position = 0
  var depth = 0
  var aim = 0

  for command in commands {
    position += command.position
    aim += command.depth
    depth += command.position * aim
  }

  print("Position: \(position)")
  print("Depth: \(depth)")
  print("Multiplied: \(position * depth)")
}
