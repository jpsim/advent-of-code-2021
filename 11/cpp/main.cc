#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <vector>
using namespace std;

// MARK: - Models

enum EnergyLevel { zero, one, two, three, four, five, six, seven, eight, nine };

EnergyLevel increase_energy_level(EnergyLevel level) {
  switch (level) {
  case zero:
    return one;
  case one:
    return two;
  case two:
    return three;
  case three:
    return four;
  case four:
    return five;
  case five:
    return six;
  case six:
    return seven;
  case seven:
    return eight;
  case eight:
    return nine;
  case nine:
    return zero;
  }
}

int raw_energy_level(EnergyLevel level) {
  switch (level) {
  case zero:
    return 0;
  case one:
    return 1;
  case two:
    return 2;
  case three:
    return 3;
  case four:
    return 4;
  case five:
    return 5;
  case six:
    return 6;
  case seven:
    return 7;
  case eight:
    return 8;
  case nine:
    return 9;
  }
}

struct Line {
  vector<EnergyLevel> levels;
};

struct Point {
  int x;
  int y;

  bool operator <(const Point& rhs) const {
    return x < rhs.x || (x == rhs.x && y < rhs.y);
  }

  bool operator ==(const Point& rhs) const {
    return x == rhs.x && y == rhs.y;
  }

  bool operator !=(const Point& rhs) const {
    return !(*this == rhs);
  }

  vector<Point> neighbors() {
    return {
      {x - 1, y - 1},
      {x - 1, y + 0},
      {x - 1, y + 1},
      {x + 0, y - 1},
      {x + 0, y + 1},
      {x + 1, y - 1},
      {x + 1, y + 0},
      {x + 1, y + 1},
    };
  }
};

struct Grid {
  map<Point, EnergyLevel> points;

  void print() {
    for (int y = 0; y < 5; ++y) {
      for (int x = 0; x < 5; ++x) {
        cout << raw_energy_level(points[{x, y}]);
      }
      cout << endl;
    }
  }

  void increase_all_points() {
    map<Point, EnergyLevel> new_points;
    for (auto i = points.begin(); i != points.end(); ++i)
      new_points[i->first] = increase_energy_level(i->second);

    points = new_points;
  }

  vector<Point> current_flash_points() {
    vector<Point> current_flash_points;
    for (auto i = points.begin(); i != points.end(); ++i)
      if (i->second == zero)
        current_flash_points.push_back(i->first);

    return current_flash_points;
  }

  int advance_step() {
    increase_all_points();
    vector<Point> seen_flash_points = current_flash_points();

    vector<Point> new_flash_points = seen_flash_points;

    while (!new_flash_points.empty()) {
      vector<Point> points_to_increase;
      for (auto i = new_flash_points.begin(); i != new_flash_points.end(); ++i) {
        vector<Point> neighbors = i->neighbors();
        points_to_increase.insert(points_to_increase.begin(), neighbors.begin(), neighbors.end());
      }

      new_flash_points.clear();

      map<Point, EnergyLevel> new_points;
      for (auto i = points.begin(); i != points.end(); ++i) {
        Point point = i->first;
        EnergyLevel new_energy_level = i->second;
        for (auto p = points_to_increase.begin(); p != points_to_increase.end(); ++p) {
          if (*p != point || count(seen_flash_points.begin(), seen_flash_points.end(), point) > 0) {
            new_points[point] = i->second;
            continue;
          }

          new_energy_level = increase_energy_level(new_energy_level);

          if (new_energy_level == zero) {
            seen_flash_points.push_back(point);
            new_flash_points.push_back(point);
          }
        }

        new_points[point] = new_energy_level;
      }

      points = new_points;
    }

    return seen_flash_points.size();
  }
};

Grid grid_from_lines(vector<Line> lines) {
  map<Point, EnergyLevel> points;
  for (int y = 0; y < lines.size(); ++y) {
    Line line = lines[y];
    for (int x = 0; x < line.levels.size(); ++x) {
      points[{x, y}] = line.levels[x];
    }
  }
  return {points};
}

// MARK: - Parsers

EnergyLevel parse_energy_level(char input) {
  switch (input) {
  case '0':
    return EnergyLevel::zero;
  case '1':
    return EnergyLevel::one;
  case '2':
    return EnergyLevel::two;
  case '3':
    return EnergyLevel::three;
  case '4':
    return EnergyLevel::four;
  case '5':
    return EnergyLevel::five;
  case '6':
    return EnergyLevel::six;
  case '7':
    return EnergyLevel::seven;
  case '8':
    return EnergyLevel::eight;
  case '9':
    return EnergyLevel::nine;
  default:
    abort();
  }
}

Line parse_line(string input) {
  vector<EnergyLevel> points;
  for (auto i = input.begin(); i != input.end(); ++i) {
    points.push_back(parse_energy_level(*i));
  }
  return {points};
}

// MARK: - Parts 1 & 2

int part1(Grid grid) {
  int sum = 0;
  for (int i = 0; i < 100; ++i) {
    sum += grid.advance_step();
  }
  return sum;
}

int part2(Grid grid) {
  for (int i = 1; i < 100000; ++i)
    if (grid.advance_step() == 100)
      return i;

  abort();
}

int main() {
  // MARK: - Read Input

  ifstream is("input.txt");
  string str;
  vector<Line> parsed_lines;
  while(getline(is, str)) {
    parsed_lines.push_back(parse_line(str));
  }

  Grid grid = grid_from_lines(parsed_lines);
  cout << "Part 1: " << part1(grid) << endl;
  cout << "Part 2: " << part2(grid) << endl;
  return 0;
}
