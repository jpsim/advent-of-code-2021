#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <vector>
using namespace std;

// MARK: - Models

enum ChunkSide { opening, closing };

enum ChunkType { round, square, curly, angle };

int corruption_points(ChunkType type) {
  switch (type) {
  case round:
    return 3;
  case square:
    return 57;
  case curly:
    return 1197;
  case angle:
    return 25137;
  }
}

uint64_t autocomplete_points(ChunkType type) {
  switch (type) {
  case round:
    return 1;
  case square:
    return 2;
  case curly:
    return 3;
  case angle:
    return 4;
  }
}

struct ChunkDelimiter {
  ChunkSide side;
  ChunkType type;
};

enum RawLineState { valid, incomplete, corrupt };

struct LineState {
  RawLineState raw_state;
  vector<ChunkType> types;

  int corruption_points() {
    switch (raw_state) {
    case valid:
      return 0;
    case incomplete:
      return 0;
    case corrupt:
      return ::corruption_points(types[0]);
    }
  }

  uint64_t autocomplete_points() {
    switch (raw_state) {
    case valid:
      return 0;
    case corrupt:
      return 0;
    case incomplete:
      uint64_t result = 0;
      for (auto i = types.rbegin(); i != types.rend(); ++i) {
        result *= 5;
        result += ::autocomplete_points(*i);
      }
      return result;
    }
  }
};

struct Line {
  vector<ChunkDelimiter> delimiters;

  LineState state() {
    vector<ChunkType> open_types;
    for (auto d = delimiters.begin(); d != delimiters.end(); ++d) {
      if (d->side == opening) {
        open_types.push_back(d->type);
      } else if (!open_types.empty() && d->type == open_types[open_types.size() - 1]) {
        open_types.pop_back();
      } else {
        return {corrupt, {d->type}};
      }
    }

    return {open_types.empty() ? valid : incomplete, open_types};
  }
};

// MARK: - Parsers

ChunkDelimiter parse_delimiter(char input) {
  switch (input) {
  case '(':
    return {opening, round};
  case '[':
    return {opening, square};
  case '{':
    return {opening, curly};
  case '<':
    return {opening, angle};
  case ')':
    return {closing, round};
  case ']':
    return {closing, square};
  case '}':
    return {closing, curly};
  case '>':
    return {closing, angle};
  default:
    abort();
  }
}

Line parse_line(string input) {
  vector<ChunkDelimiter> delimiters;
  for (auto i = input.begin(); i != input.end(); ++i) {
    delimiters.push_back(parse_delimiter(*i));
  }
  return {delimiters};
}

// MARK: - Parts 1 & 2

int part1(vector<LineState> line_states) {
  int sum = 0;
  for (auto i = line_states.begin(); i != line_states.end(); ++i) {
    sum += i->corruption_points();
  }
  return sum;
}

uint64_t part2(vector<LineState> line_states) {
  vector<uint64_t> autocomplete_points;
  for (auto i = line_states.begin(); i != line_states.end(); ++i) {    
    uint64_t points = i->autocomplete_points();
    if (points > 0)
      autocomplete_points.push_back(points);
  }

  sort(autocomplete_points.begin(), autocomplete_points.end());
  return autocomplete_points[(autocomplete_points.size() - 1) / 2];
}

int main() {
  // MARK: - Read Input

  ifstream is("input.txt");
  string str;
  vector<LineState> line_states;
  while(getline(is, str)) {
    line_states.push_back(parse_line(str).state());
  }

  cout << "Part 1: " << part1(line_states) << endl;
  cout << "Part 2: " << part2(line_states) << endl;
  return 0;
}
