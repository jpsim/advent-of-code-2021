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
}

// MARK: - Models

final class DeterministicDie {
  private var next = 1

  var numberOfRolls: Int {
    next - 1
  }

  func roll() -> Int {
    defer { next += 1 }
    return next
  }

  func roll(times: Int) -> Int {
    (0..<times).reduce(0) { result, _ in result + roll() }
  }
}

struct PlayerState {
  let player: Int
  var position: Int
  var score: Int

  mutating func playTurn(roll: Int) {
    position += roll
    position %= 10
    if position == 0 {
      position = 10
    }
    score += position
  }

  var hasWonDeterministic: Bool {
    score >= 1000
  }

  var hasWonDirac: Bool {
    score >= 21
  }
}

struct DeterministicGame {
  var player1: PlayerState
  var player2: PlayerState
  let die = DeterministicDie()
  var numberOfTurns = 0

  init(player1: PlayerState, player2: PlayerState) {
    self.player1 = player1
    self.player2 = player2
  }

  var hasWinner: Bool {
    player1.hasWonDeterministic || player2.hasWonDeterministic
  }

  mutating func playTurn() {
    player1.playTurn(roll: die.roll(times: 3))
    guard !player1.hasWonDeterministic else {
      return
    }

    player2.playTurn(roll: die.roll(times: 3))
    numberOfTurns += 1
  }

  var losingScore: Int {
    min(player1.score, player2.score)
  }

  mutating func playUntilWin() {
    while !hasWinner {
      playTurn()
    }
  }
}

struct DiracGame {
  let player1: PlayerState
  let player2: PlayerState
  let universes: Int

  init(player1: PlayerState, player2: PlayerState, universes: Int = 1) {
    self.player1 = player1
    self.player2 = player2
    self.universes = universes
  }

  // key is dirac sum after 3 rolls
  // value is the number of times that can happen
  static let rollWeights = [1, 2, 3].flatMap { first in
    [1, 2, 3].flatMap { second in
      [1, 2, 3].map { third in
        first + second + third
      }
    }
  }
  .reduce(into: [Int: Int]()) { $0[$1, default: 0] += 1 }

  func playTurn() -> [DiracGame] {
    return DiracGame.rollWeights.flatMap { roll, firstWeight -> [DiracGame] in
      var newPlayer1 = player1
      newPlayer1.playTurn(roll: roll)
      guard !newPlayer1.hasWonDirac else {
        return [DiracGame(player1: newPlayer1, player2: player2, universes: universes * firstWeight)]
      }

      return DiracGame.rollWeights.map { roll, secondWeight -> DiracGame in
        var newPlayer2 = player2
        newPlayer2.playTurn(roll: roll)
        return DiracGame(player1: newPlayer1, player2: newPlayer2, universes: universes * firstWeight * secondWeight)
      }
    }
  }

  func maxUniverseWinsForPlayer() -> Int {
    var inProgressGames = [self]
    var player1Universes = 0
    var player2Universes = 0

    while !inProgressGames.isEmpty {
      let result = inProgressGames.parallelMap { game -> (Int, Int, [DiracGame]) in
        var inProgressGames = [DiracGame]()
        var player1Universes = 0
        var player2Universes = 0

        let gamesAfterTurn = game.playTurn()

        for gameAfterTurn in gamesAfterTurn {
          if gameAfterTurn.player1.hasWonDirac {
            player1Universes += gameAfterTurn.universes
          } else if gameAfterTurn.player2.hasWonDirac {
            player2Universes += gameAfterTurn.universes
          } else {
            inProgressGames.append(gameAfterTurn)
          }
        }

        return (player1Universes, player2Universes, inProgressGames)
      }

      player1Universes += result.reduce(0) { $0 + $1.0 }
      player2Universes += result.reduce(0) { $0 + $1.1 }
      inProgressGames = result.reduce(into: []) { $0.append(contentsOf: $1.2) }
    }

    return max(player1Universes, player2Universes)
  }
}

// MARK: - Parsers

let playerState = Skip("Player ")
  .take(Int.parser())
  .skip(" starting position: ")
  .take(Int.parser())
  .take(Always(0))
  .map(PlayerState.init)

let parser = playerState
  .skip("\n")
  .take(playerState)

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let (player1InitialState, player2InitialState) = parser.parse(&input)!

// MARK: - Parts 1 & 2

func partOne() -> Int {
  var game = DeterministicGame(player1: player1InitialState, player2: player2InitialState)
  game.playUntilWin()
  return game.losingScore * game.die.numberOfRolls
}

func partTwo() -> Int {
  DiracGame(player1: player1InitialState, player2: player2InitialState)
    .maxUniverseWinsForPlayer()
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
