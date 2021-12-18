#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <vector>
using namespace std;

// MARK: - Split

vector<string> split(string str, string token){
    vector<string>result;
    while(str.size()){
        int index = str.find(token);
        if (index != string::npos) {
            result.push_back(str.substr(0,index));
            str = str.substr(index+token.size());
            if (str.empty()) result.push_back(str);
        } else {
            result.push_back(str);
            str = "";
        }
    }
    return result;
}

// MARK: - Models

struct Coordinate {
  int x;
  int y;
};

struct VentLine {
  Coordinate start;
  Coordinate end;

  bool is_horizontal() {
    return start.x == end.x || start.y == end.y;
  }

  bool is_diagonal() {
    return abs(start.x - end.x) == abs(start.y - end.y);
  }

  int min_x() {
    return min(start.x, end.x);
  }

  int max_x() {
    return max(start.x, end.x);
  }

  int min_y() {
    return min(start.y, end.y);
  }

  int max_y() {
    return max(start.y, end.y);
  }

  vector<Coordinate> interpolated_coordinates() {
    vector<Coordinate> coordinates;
    if (start.x == end.x) {
      for (int i = min_y(); i <= max_y(); ++i) {
        coordinates.push_back({start.x, i});
      }
    } else if (start.y == end.y) {
      for (int i = min_x(); i <= max_x(); ++i) {
        coordinates.push_back({i, start.y});
      }
    } else {
      // Assuming diagonal
      int steps = abs(start.x - end.x) + 1;
      int x_direction = start.x < end.x ? 1 : -1;
      int y_direction = start.y < end.y ? 1 : -1;

      for (int step = 0; step < steps; ++step) {
        int x = start.x + (step * x_direction);
        int y = start.y + (step * y_direction);
        coordinates.push_back({x, y});
      }
    }

    return coordinates;
  }
};

struct Grid {
  vector<vector<int>> rows;

  void build_from_lines(vector<VentLine> lines, int max_x, int max_y) {
    map<pair<int, int>, int> coordinate_counts;
    for (auto l = lines.begin(); l != lines.end(); ++l)
    {
      vector<Coordinate> line_coordinates = l->interpolated_coordinates();
      for (auto c = line_coordinates.begin(); c != line_coordinates.end(); ++c)
      {
        coordinate_counts[{c->x, c->y}]++;
      }
    }
    for (int y = 0; y <= max_y; ++y) {
      vector<int> row;
      for (int x = 0; x <= max_x; ++x) {
        row.push_back(coordinate_counts[{x, y}]);
      }
      rows.push_back(row);
    }
  }

  void pretty_print() {
    for (auto r = rows.begin(); r != rows.end(); ++r) {
      for (auto c = r->begin(); c != r->end(); ++c) {
        if (*c == 0)
          cout << ".";
        else
          cout << *c;
      }

      cout << endl;
    }
  }

  int points_where_two_or_more_lines_overlap() {
    int result = 0;
    for (auto r = rows.begin(); r != rows.end(); ++r) {
      for (auto c = r->begin(); c != r->end(); ++c) {
        if (*c >= 2)
          result++;
      }
    }
    return result;
  }
};

// MARK: - Parsing

Coordinate string_to_coordinate(string input) {
  vector<string> x_and_y = split(input, ",");
  return {stoi(x_and_y[0]), stoi(x_and_y[1])};
}

VentLine string_to_vent_line(string input) {
  VentLine vent_line;
  vector<string> start_and_end_coordinates = split(input, " -> ");
  vent_line.start = string_to_coordinate(start_and_end_coordinates[0]);
  vent_line.end = string_to_coordinate(start_and_end_coordinates[1]);
  return vent_line;
}

// MARK: - Main

int main() {
  // MARK: - Read Input

  ifstream is("input.txt");
  vector<VentLine> input_lines;
  string str_line;
  int max_x = 0;
  int max_y = 0;
  while(getline(is, str_line)) {
    VentLine vent_line = string_to_vent_line(str_line);
    input_lines.push_back(vent_line);
    max_x = max(max_x, max(vent_line.start.x, vent_line.end.x));
    max_y = max(max_y, max(vent_line.start.y, vent_line.end.y));
  }

  // MARK: - Part 1

  cout << "# Part 1" << endl;

  vector<VentLine> part1_lines;
  for (auto l = input_lines.begin(); l != input_lines.end(); ++l) {
    if (l->is_horizontal())
      part1_lines.push_back(*l);
  }

  Grid part1_grid;
  part1_grid.build_from_lines(part1_lines, max_x, max_y);
  // part1_grid.pretty_print();

  int part1_answer = part1_grid.points_where_two_or_more_lines_overlap();
  cout << part1_answer << " points have at least two lines overlapping" << endl;

  // MARK: - Part 2

  cout << "# Part 2" << endl;

  vector<VentLine> part2_lines;
  for (auto l = input_lines.begin(); l != input_lines.end(); ++l) {
    if (l->is_horizontal() || l->is_diagonal())
      part2_lines.push_back(*l);
  }

  Grid part2_grid;
  part2_grid.build_from_lines(part2_lines, max_x, max_y);
  // part2_grid.pretty_print();

  int part2_answer = part2_grid.points_where_two_or_more_lines_overlap();
  cout << part2_answer << " points have at least two lines overlapping" << endl;
  return 0;
}
