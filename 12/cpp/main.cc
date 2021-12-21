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

struct Cave {
  uint8_t id;
  bool is_small;

  bool operator ==(const Cave& rhs) const {
    return id == rhs.id;
  }

  bool operator !=(const Cave& rhs) const {
    return id != rhs.id;
  }

  bool operator <(const Cave& rhs) const {
    return id < rhs.id;
  }

  static Cave start() {
    return {0, true};
  }

  static Cave end() {
    return {1, true};
  }
};

struct Segment {
  Cave cave1;
  Cave cave2;

  bool contains(Cave cave) {
    return cave == cave1 || cave == cave2;
  }

  Cave other(Cave cave) {
    return cave == cave1 ? cave2 : cave1;
  }
};

struct Path {
  vector<Cave> caves;

  bool operator ==(const Path& rhs) const {
    return caves == rhs.caves;
  }

  bool operator <(const Path& rhs) const {
    return caves < rhs.caves;
  }

  bool is_valid(bool part1) {
    set<Cave> visited_caves;
    bool did_visit_small_cave_twice = false;
    for (auto i = caves.begin(); i != caves.end(); ++i) {
      Cave cave = *i;
      if (!cave.is_small) {
        continue;
      } else if (count(visited_caves.begin(), visited_caves.end(), cave) == 0) {
        visited_caves.insert(cave);
      } else if (part1) {
        return false;
      } else if (did_visit_small_cave_twice) {
        return false;
      } else if (cave == Cave::start() || cave == Cave::end()) {
        return false;
      } else {
        did_visit_small_cave_twice = true;
      }
    }

    return true;
  }

  bool reaches_end() const {
    return caves[caves.size() - 1] == Cave::end();
  }
};

struct Map {
  vector<Segment> segments;

  vector<Cave> caves_accessible(Cave cave) {
    vector<Cave> result;
    for (auto i = segments.begin(); i != segments.end(); ++i)
      if (i->contains(cave))
        result.push_back(i->other(cave));

    return result;
  }

  int complete_paths(bool part1) {
    vector<Cave> start_accessibles = caves_accessible(Cave::start());
    vector<Path> possible_paths;
    for (auto i = start_accessibles.begin(); i != start_accessibles.end(); ++i)
      possible_paths.push_back({{Cave::start(), *i}});

    set<Path> complete_paths;
    while (!possible_paths.empty()) {
      set<Path> new_possible_paths;
      for (auto i = possible_paths.begin(); i != possible_paths.end(); ++i) {
        vector<Path> more = generate_more(*i, part1);
        for (auto m = more.begin(); m != more.end(); ++m)
          if (count(complete_paths.begin(), complete_paths.end(), *m) == 0)
            new_possible_paths.insert(*m);
      }

      possible_paths.clear();
      for (auto i = new_possible_paths.begin(); i != new_possible_paths.end(); ++i) {
        if (i->reaches_end()) {
          complete_paths.insert(*i);
        } else {
          possible_paths.push_back(*i);
        }
      }
    }

    return complete_paths.size();
  }

  vector<Path> generate_more(Path path, bool part1) {
    vector<Cave> accessibles = caves_accessible(path.caves[path.caves.size() - 1]);
    vector<Path> result;
    for (auto i = accessibles.begin(); i != accessibles.end(); ++i) {
      Path new_path = path;
      new_path.caves.push_back(*i);
      if (new_path.is_valid(part1))
        result.push_back(new_path);
    }
    return result;
  }
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

Segment parse_segment(string input) {
  vector<string> segment_strings = split(input, "-");
  Cave cave1 = {get_id_for_name(segment_strings[0]), islower(segment_strings[0][0]) > 0};
  Cave cave2 = {get_id_for_name(segment_strings[1]), islower(segment_strings[1][0]) > 0};
  return {cave1, cave2};
}

// MARK: - Parts 1 & 2

int part1(Map map) {
  return map.complete_paths(true);
}

int part2(Map map) {
  return map.complete_paths(false);
}

int main() {
  // MARK: - Read Input

  ifstream is("input.txt");
  string str;
  vector<Segment> parsed_segments;
  while(getline(is, str)) {
    parsed_segments.push_back(parse_segment(str));
  }

  Map map = {parsed_segments};
  cout << "Part 1: " << part1(map) << endl;
  cout << "Part 2: " << part2(map) << endl;
  return 0;
}
