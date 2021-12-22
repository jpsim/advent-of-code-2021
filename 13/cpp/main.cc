#include <algorithm>
#include <fstream>
#include <cctype>
#include <iterator>
#include <iostream>
#include <cstring>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <vector>
using namespace std;

// MARK: - ID Factory

uint8_t get_id_for_name(string name) {
  static map<string, uint8_t> mapping({{"start", 0}, {"end", 1}});
  static uint8_t next_id = 2;
  if (mapping.count(name))
    return mapping[name];

  next_id++;
  mapping[name] = next_id;
  return next_id;
}

// MARK: - Models

enum InstructionType { fold_up, fold_left };

struct Instruction {
  InstructionType type;
  int value;
};

struct Dot {
  int x;
  int y;

  bool operator ==(const Dot& rhs) const {
    return x == rhs.x && y == rhs.y;
  }

  bool operator <(const Dot& rhs) const {
    return x < rhs.x || (x == rhs.x && y < rhs.y);
  }
};

struct Grid {
  vector<Dot> dots;
  int max_x;
  int max_y;

  string description() {
    string description;
    for (int y = 0; y <= max_y; ++y) {
      for (int x = 0; x <= max_x; ++x) {
        Dot dot({x, y});
        bool has_dot = count(dots.begin(), dots.end(), dot) > 0;
        description += has_dot ? "#" : ".";
      }
      description += "\n";
    }
    return description;
  }

  Grid folding(Instruction instruction) {
    vector<Dot> new_dots = dots;
    int new_max_x = max_x;
    int new_max_y = max_y;
    int value = instruction.value;
    switch (instruction.type) {
    case fold_up:
      new_max_y = value - 1;
      for (int y = value + 1; y <= max_y; ++y) {
        int new_y = value - (y - value);
        for (int i = 0; i < new_dots.size(); ++i)
          if (new_dots[i].y == y)
            new_dots[i] = {new_dots[i].x, new_y};
      }
      break;
    case fold_left:
      new_max_x = value - 1;
      for (int x = value + 1; x <= max_x; ++x) {
        int new_x = value - (x - value);
        for (int i = 0; i < new_dots.size(); ++i)
          if (new_dots[i].x == x)
            new_dots[i] = {new_x, new_dots[i].y};
      }
      break;
    }

    set<Dot> new_dots_set(new_dots.begin(), new_dots.end());
    vector<Dot> new_dots_unique(new_dots_set.begin(), new_dots_set.end());
    return {new_dots_unique, new_max_x, new_max_y};
  }
};

struct Line {
  optional<Dot> dot;
  optional<Instruction> instruction;
};

// MARK: - Parsers

vector<string> split(string str, string token){
  vector<string>result;
  while (str.size()) {
    int index = str.find(token);
    if (index != string::npos) {
      result.push_back(str.substr(0, index));
      str = str.substr(index+token.size());
      if (str.empty()) result.push_back(str);
    } else {
      result.push_back(str);
      str = "";
    }
  }
  return result;
}

Line parse_line(string input) {
  vector<string> dot_members = split(input, ",");
  if (dot_members.size() == 2) {
    Dot dot({stoi(dot_members[0]), stoi(dot_members[1])});
    return {dot, nullopt};
  }

  bool contains_x = input.find("x=") != string::npos;
  InstructionType instruction_type = InstructionType::fold_up;
  if (contains_x)
    instruction_type = InstructionType::fold_left;

  int value = stoi(split(input, "=")[1]);
  Instruction instruction = {instruction_type, value};
  return {nullopt, instruction};
}

// MARK: - Parts 1 & 2

int part1(Grid grid, vector<Instruction> instructions) {
  return grid.folding(instructions[0]).dots.size();
}

string part2(Grid grid, vector<Instruction> instructions) {
  for (auto i = instructions.begin(); i != instructions.end(); ++i) {
    grid = grid.folding(*i);
  }
  return grid.description();
}

int main() {
  // MARK: - Read Input

  ifstream is("input.txt");
  string str;
  vector<Line> parsed_lines;
  while(getline(is, str)) {
    if (!str.empty())
      parsed_lines.push_back(parse_line(str));
  }

  vector<Dot> dots;
  int max_x = 0;
  int max_y = 0;
  for (auto i = parsed_lines.begin(); i != parsed_lines.end(); ++i) {
    if (i->dot.has_value()) {
      Dot dot = i->dot.value();
      dots.push_back(dot);
      max_x = max(max_x, dot.x);
      max_y = max(max_y, dot.y);
    }
  }

  vector<Instruction> instructions;
  for (auto i = parsed_lines.begin(); i != parsed_lines.end(); ++i)
    if (i->instruction.has_value())
      instructions.push_back(i->instruction.value());

  Grid grid = {dots, max_x, max_y};
  cout << "Part 1: " << part1(grid, instructions) << endl;
  cout << "Part 2:" << endl << part2(grid, instructions);
  return 0;
}
