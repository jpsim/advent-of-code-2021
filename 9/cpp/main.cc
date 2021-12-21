#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <vector>
using namespace std;

// MARK: - Models

struct Point {
  int x;
  int y;

  bool operator <(const Point& rhs) const {
    return x < rhs.x || (x == rhs.x && y < rhs.y);
  }

  bool operator ==(const Point& rhs) const {
    return x == rhs.x && y == rhs.y;
  }
};

enum Height { zero, one, two, three, four, five, six, seven, eight, nine };

int height_to_raw_value(Height height) {
  switch (height) {
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

int height_to_risk_level(Height height) {
  return height_to_raw_value(height) + 1;
}

struct Line {
  vector<Height> points;
};

struct PointWithHeight {
  Point point;
  Height height;

  bool operator <(const PointWithHeight& rhs) const {
    return point < rhs.point || (point == rhs.point && height_to_raw_value(height) < height_to_raw_value(rhs.height));
  }

  bool operator ==(const PointWithHeight& rhs) const {
    return point == rhs.point && height_to_raw_value(height) == height_to_raw_value(rhs.height);
  }
};

vector<PointWithHeight> low_point_candidates(vector<PointWithHeight> input) {
  vector<PointWithHeight> results;
  for (int i = 0; i < input.size() - 2; ++i) {
    if (input[i].height > input[i + 1].height && input[i + 2].height > input[i + 1].height)
      results.push_back(input[i + 1]);
  }

  if (input[0].height < input[1].height)
    results.push_back(input[0]);

  if (input[input.size() - 1].height < input[input.size() - 2].height)
    results.push_back(input[input.size() - 1]);

  return results;
}

struct Basin {
  vector<PointWithHeight> points;

  int size() { return points.size(); }
};

vector<PointWithHeight> points_adjacent_to(Point point, vector<PointWithHeight> input) {
  vector<Point> adjacent_positions = {
    {point.x + 1, point.y},
    {point.x - 1, point.y},
    {point.x, point.y + 1},
    {point.x, point.y - 1},
  };

  vector<PointWithHeight> results;
  for (auto i = adjacent_positions.begin(); i != adjacent_positions.end(); ++i)
    for (auto p = input.begin(); p != input.end(); ++p)
      if (*i == p->point)
        results.push_back(*p);

  return results;
}

vector<PointWithHeight> points_adjacent_to(vector<PointWithHeight> points, vector<PointWithHeight> input) {
  vector<PointWithHeight> results;
  for (auto p = points.begin(); p != points.end(); ++p) {
    vector<PointWithHeight> adjacent_points = points_adjacent_to(p->point, input);
    results.insert(results.end(), adjacent_points.begin(), adjacent_points.end());
  }
  unique(results.begin(), results.end());
  auto it = unique(results.begin(), results.end());
  results.resize(distance(results.begin(), it));
  return results;
}

struct Grid {
  map<Point, Height> points;
  Point max_point;

  vector<PointWithHeight> get_low_points() {
    vector<PointWithHeight> x_low_point_candidates;
    for (int y = 0; y <= max_point.y; ++y) {
      vector<PointWithHeight> points_matching_y;
      for (auto p = points.begin(); p != points.end(); ++p)
        if (p->first.y == y)
          points_matching_y.push_back({p->first, p->second});

      sort(points_matching_y.begin(), points_matching_y.end());
      auto candidates = low_point_candidates(points_matching_y);
      for (auto c = candidates.begin(); c != candidates.end(); ++c)
        x_low_point_candidates.push_back(*c);
    }

    vector<PointWithHeight> y_low_point_candidates;
    for (int x = 0; x <= max_point.x; ++x) {
      vector<PointWithHeight> points_matching_x;
      for (auto p = points.begin(); p != points.end(); ++p)
        if (p->first.x == x)
          points_matching_x.push_back({p->first, p->second});

      sort(points_matching_x.begin(), points_matching_x.end());
      auto candidates = low_point_candidates(points_matching_x);
      for (auto c = candidates.begin(); c != candidates.end(); ++c)
        y_low_point_candidates.push_back(*c);
    }

    sort(x_low_point_candidates.begin(), x_low_point_candidates.end());
    sort(y_low_point_candidates.begin(), y_low_point_candidates.end());
    
    vector<PointWithHeight> result;
    set_intersection(x_low_point_candidates.begin(), x_low_point_candidates.end(),
                     y_low_point_candidates.begin(), y_low_point_candidates.end(),
                     back_inserter(result));
    sort(result.begin(), result.end());
    return result;
  }

  vector<Basin> get_basins() {
    vector<Basin> result;
    vector<PointWithHeight> eligible_points;
    for (auto i = points.begin(); i != points.end(); ++i)
      if (i->second != nine)
        eligible_points.push_back({i->first, i->second});

    vector<PointWithHeight> low_points = get_low_points();
    for (auto p = low_points.begin(); p != low_points.end(); ++p) {
      eligible_points.erase(
        remove(eligible_points.begin(), eligible_points.end(), *p),
        eligible_points.end()
      );

      vector<PointWithHeight> basin_points = {*p};
      bool finished_basin = false;
      while (!finished_basin) {
        vector<PointWithHeight> adjacent_points = points_adjacent_to(basin_points, eligible_points);
        if (adjacent_points.empty()) {
          finished_basin = true;
        } else {
          basin_points.insert(basin_points.end(), adjacent_points.begin(), adjacent_points.end());
          auto it = eligible_points.begin();
          while (it != eligible_points.end()) {
            if (count(adjacent_points.begin(), adjacent_points.end(), *it) > 0) {
              it = eligible_points.erase(it);
            } else {
              ++it;
            }
          }
        }
      }

      vector<PointWithHeight> unique_basin_points;
      for (auto bp = basin_points.begin(); bp != basin_points.end(); ++bp) {
        if (count(unique_basin_points.begin(), unique_basin_points.end(), *bp) == 0)
          unique_basin_points.push_back(*bp);
      }

      result.push_back({unique_basin_points});
    }

    assert(eligible_points.empty());
    return result;
  }
};

Grid grid_from_lines(vector<Line> lines) {
  map<Point, Height> points;
  for (int y = 0; y < lines.size(); ++y) {
    Line line = lines[y];
    for (int x = 0; x < line.points.size(); ++x) {
      points[{x, y}] = line.points[x];
    }
  }

  Point max_point = points.rbegin()->first;
  return {points, max_point};
}

// MARK: - Parsers

Height parse_height(char input) {
  switch (input) {
  case '0':
    return Height::zero;
  case '1':
    return Height::one;
  case '2':
    return Height::two;
  case '3':
    return Height::three;
  case '4':
    return Height::four;
  case '5':
    return Height::five;
  case '6':
    return Height::six;
  case '7':
    return Height::seven;
  case '8':
    return Height::eight;
  case '9':
    return Height::nine;
  default:
    abort();
  }
}

Line parse_line(string input) {
  vector<Height> points;
  for (auto i = input.begin(); i != input.end(); ++i) {
    points.push_back(parse_height(*i));
  }
  return {points};
}

// MARK: - Parts 1 & 2

int part1(Grid grid) {
  auto low_points = grid.get_low_points();
  int sum = 0;
  for (auto i = low_points.begin(); i != low_points.end(); ++i) {
    sum += height_to_risk_level(i->height);
  }
  return sum;
}

int part2(Grid grid) {
  auto basins = grid.get_basins();
  vector<int> basin_sizes;
  for (auto i = basins.begin(); i != basins.end(); ++i) {
    basin_sizes.push_back(i->size());
  }

  sort(basin_sizes.begin(), basin_sizes.end());
  int result = basin_sizes[basins.size() - 1];
  result *= basin_sizes[basins.size() - 2];
  result *= basin_sizes[basins.size() - 3];
  return result;
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
