import Foundation
import Parsing

// MARK: - Models

struct Point: Hashable {
  var x: Int
  var y: Int
  var z: Int

  var magnitude: Int { abs(x) + abs(y) + abs(z) }

  static let zero = Point(x: 0, y: 0, z: 0)

  static let permutations: [(Point) -> Point] = [
    { Point(x: $0.x, y: $0.y, z: $0.z) },
    { Point(x: $0.x, y: -$0.z, z: $0.y) },
    { Point(x: $0.x, y: -$0.y, z: -$0.z) },
    { Point(x: $0.x, y: $0.z, z: -$0.y) },

    { Point(x: -$0.x, y: $0.y, z: -$0.z) },
    { Point(x: -$0.x, y: -$0.z, z: -$0.y) },
    { Point(x: -$0.x, y: -$0.y, z: $0.z) },
    { Point(x: -$0.x, y: $0.z, z: $0.y) },

    { Point(x: $0.y, y: $0.x, z: -$0.z) },
    { Point(x: $0.y, y: -$0.z, z: -$0.x) },
    { Point(x: $0.y, y: -$0.x, z: $0.z) },
    { Point(x: $0.y, y: $0.z, z: $0.x) },

    { Point(x: -$0.y, y: $0.x, z: $0.z) },
    { Point(x: -$0.y, y: -$0.z, z: $0.x) },
    { Point(x: -$0.y, y: -$0.x, z: -$0.z) },
    { Point(x: -$0.y, y: $0.z, z: -$0.x) },

    { Point(x: $0.z, y: $0.y, z: -$0.x) },
    { Point(x: $0.z, y: $0.x, z: $0.y) },
    { Point(x: $0.z, y: -$0.y, z: $0.x) },
    { Point(x: $0.z, y: -$0.x, z: -$0.y) },

    { Point(x: -$0.z, y: $0.y, z: $0.x) },
    { Point(x: -$0.z, y: -$0.x, z: $0.y) },
    { Point(x: -$0.z, y: -$0.y, z: -$0.x) },
    { Point(x: -$0.z, y: $0.x, z: -$0.y) },
  ]

  static func + (lhs: Point, rhs: Point) -> Point {
    Point(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
  }

  static func - (lhs: Point, rhs: Point) -> Point {
    Point(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
  }

  static func / (lhs: Point, rhs: Int) -> Point {
    Point(x: lhs.x / rhs, y: lhs.y / rhs, z: lhs.z / rhs)
  }
}

struct Report {
  let scanner: Int
  var points: Set<Point>
  var center: Point?

  init(scanner: Int, points: Set<Point>) {
    self.scanner = scanner
    self.points = points
    self.center = nil
  }

  func pointDistances() -> Set<Point> {
    Set(points.flatMap { point in
      points
        .subtracting([point])
        .map { point - $0 }
    })
  }

  func permutations() -> [Report] {
    Point.permutations.map { rotation in
      Report(scanner: scanner, points: Set(points.map(rotation)))
    }
  }

  func intersection(with other: Set<Point>) -> Set<Point> {
    Set(points.filter { point in
      points
        .map { $0 - point }
        .filter(other.contains)
        .count >= 11
    })
  }

  mutating func translate(by translation: Point) {
    points = Set(points.map { $0 + translation })
    center = translation
  }

  /// Translate and anchor reports relative to self.
  func anchor(_ reports: [Report]) -> [Report] {
    var anchoredReport = self
    anchoredReport.center = .zero
    var anchoredReports = [anchoredReport]

    while anchoredReports.count != reports.count {
      for report in reports where !anchoredReports.contains(where: { $0.scanner == report.scanner }) {
        let anchoredPointDistances = anchoredReport.pointDistances()
        for permuted in report.permutations() {
          let intersection = permuted.pointDistances().intersection(anchoredPointDistances)
          guard intersection.count >= 32 else {
            continue
          }

          let anchoredIntersection = anchoredReport.intersection(with: intersection)
          let permutedIntersection = permuted.intersection(with: intersection)
          let count = permutedIntersection.count
          guard anchoredIntersection.count == count else {
            continue
          }

          let translation = (anchoredIntersection.reduce(.zero, +) - permutedIntersection.reduce(.zero, +)) / count
          var translatedReport = permuted
          translatedReport.translate(by: translation)

          if translatedReport.points.filter(anchoredReport.points.contains).count == count {
            anchoredReports.append(translatedReport)
            break
          }
        }
      }

      anchoredReport = anchoredReports
        .drop(while: { $0.scanner != anchoredReport.scanner })
        .dropFirst()
        .first!
    }

    return anchoredReports
  }
}

extension Sequence where Element == Report {
  func numberOfBeacons() -> Int {
    reduce(into: Set<Point>()) { $0.formUnion($1.points) }
    .count
  }

  func furthestScannerDistance() -> Int {
    let scannerPositions = map(\.center!)
    return scannerPositions
      .flatMap { position in
        scannerPositions.map { ($0 - position).magnitude }
      }
      .max()!
  }
}

// MARK: - Parsers

let point = Int.parser()
  .skip(",")
  .take(Int.parser())
  .skip(",")
  .take(Int.parser())
  .map(Point.init)

let points = Many(point, separator: "\n")
  .map(Set.init)

let report = Skip("--- scanner ")
  .take(Int.parser())
  .skip(" ---\n")
  .take(points)
  .map(Report.init)

let parser = Many(report, separator: "\n\n")

// MARK: - Read Input

var input = try String(contentsOfFile: "input.txt", encoding: .utf8)[...]
let reports = parser.parse(&input)!

// MARK: - Parts 1 & 2

let anchoredReports = reports[0].anchor(reports)

func partOne() -> Int {
  anchoredReports.numberOfBeacons()
}

func partTwo() -> Int {
  anchoredReports.furthestScannerDistance()
}

print("Part 1:", partOne())
print("Part 2:", partTwo())
