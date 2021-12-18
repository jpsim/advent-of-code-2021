import Foundation

// MARK: - Models

final class BingoBoard {
  let rows: [[Int]]

  var calledNumbers: Set<Int> = []

  func call(number: Int) {
    if rows.contains(where: { $0.contains(number) }) {
      calledNumbers.insert(number)
    }
  }

  init(lines: [String]) {
    rows = lines.map { line in
      line
        .components(separatedBy: .whitespaces)
        .compactMap(Int.init)
    }
  }

  var columns: [[Int]] {
    return (0..<5).map { column in rows.map { $0[column] } }
  }

  var didWin: Bool {
    return rows.contains(where: { calledNumbers.isSuperset(of: $0) }) ||
      columns.contains(where: { calledNumbers.isSuperset(of: $0) })
  }

  var unmarkedSum: Int {
      Set(rows.flatMap { $0 })
      .subtracting(calledNumbers)
      .reduce(0, +)
  }
}

// MARK: - Get Scores

func getScores(boards: [BingoBoard], calledNumbers: [Int]) -> (first: Int, last: Int) {
  var firstScore: Int?
  var winningBoards = [Int]()
  for number in calledNumbers {
    for (boardIndex, board) in boards.enumerated() where !winningBoards.contains(boardIndex) {
      board.call(number: number)
      if board.didWin {
        winningBoards.append(boardIndex)
        if firstScore == nil {
          firstScore = board.unmarkedSum * number
        } else if winningBoards.count == boards.count,
          let firstScore = firstScore
        {
          return (first: firstScore, last: board.unmarkedSum * number)
        }
      }
    }
  }

  fatalError("Not all boards won")
}

// MARK: - Read Input

let contents = try String(contentsOfFile: "input.txt", encoding: .utf8)
let lines = contents.components(separatedBy: .newlines)

// MARK: - Parse Called Numbers

let calledNumbers = lines[0]
  .split(separator: ",")
  .compactMap { Int($0) }

// MARK: - Parse Bingo Boards

let boards = stride(from: 2, to: lines.count, by: 6)
  .map { startLine -> [String] in
    [
      lines[startLine],
      lines[startLine + 1],
      lines[startLine + 2],
      lines[startLine + 3],
      lines[startLine + 4],
    ]
  }
  .map(BingoBoard.init)

// MARK: - Parts 1 & 2

let (first, last) = getScores(boards: boards, calledNumbers: calledNumbers)
print("first score: \(first)")
print("last score: \(last)")
