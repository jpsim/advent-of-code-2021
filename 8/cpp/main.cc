#include <fstream>
#include <iostream>
#include <map>
#include <sstream>
#include <string>
#include <vector>
using namespace std;

// MARK: - Models

enum Segment { a, b, c, d, e, f, g };

vector<Segment> all_segment_cases() {
  return { Segment::a, Segment::b, Segment::c, Segment::d, Segment::e, Segment::f, Segment::g };
}

enum Digit { zero, one, two, three, four, five, six, seven, eight, nine };

bool segments_contains(vector<Segment> segments, vector<Segment> test) {
  if (test.size() != segments.size()) {
    return false;
  }

  int matches = 0;
  for (auto i = test.begin(); i != test.end(); ++i) {
    if (count(segments.begin(), segments.end(), *i) > 0) {
      matches++;
    }
  }
  return matches == test.size();
}

optional<Digit> digit_from_segments(vector<Segment> segments) {
  if (segments_contains({Segment::a, Segment::b, Segment::c, Segment::e, Segment::f, Segment::g}, segments)) {
    return Digit::zero;
  } else if (segments_contains({Segment::c, Segment::f}, segments)) {
    return Digit::one;
  } else if (segments_contains({Segment::a, Segment::c, Segment::d, Segment::e, Segment::g}, segments)) {
    return Digit::two;
  } else if (segments_contains({Segment::a, Segment::c, Segment::d, Segment::f, Segment::g}, segments)) {
    return Digit::three;
  } else if (segments_contains({Segment::b, Segment::c, Segment::d, Segment::f}, segments)) {
    return Digit::four;
  } else if (segments_contains({Segment::a, Segment::b, Segment::d, Segment::f, Segment::g}, segments)) {
    return Digit::five;
  } else if (segments_contains({Segment::a, Segment::b, Segment::d, Segment::e, Segment::f, Segment::g}, segments)) {
    return Digit::six;
  } else if (segments_contains({Segment::a, Segment::c, Segment::f}, segments)) {
    return Digit::seven;
  } else if (segments_contains({Segment::a, Segment::b, Segment::c, Segment::d, Segment::e, Segment::f, Segment::g}, segments)) {
    return Digit::eight;
  } else if (segments_contains({Segment::a, Segment::b, Segment::c, Segment::d, Segment::f, Segment::g}, segments)) {
    return Digit::nine;
  }

  return nullopt;
}

struct SegmentMap {
  map<Segment, Segment> map;
};

vector<SegmentMap> all_possible_segment_maps() {
  vector<SegmentMap> all_maps;
  vector<Segment> original_all_segment_cases = all_segment_cases();
  vector<Segment> all_segments = all_segment_cases();

  do {
      SegmentMap map;
      for (int segment_index = 0; segment_index < original_all_segment_cases.size(); ++segment_index) {
        map.map[original_all_segment_cases[segment_index]] = all_segments[segment_index];
      }
      all_maps.push_back(map);
  } while (next_permutation(all_segments.begin(), all_segments.end()));
  return all_maps;
}

struct BrokenDigit {
  vector<Segment> segments;

  optional<Digit> to_digit(SegmentMap map) {
    vector<Segment> mapped_segments;
    for (auto i = segments.begin(); i != segments.end(); ++i) {
      mapped_segments.push_back(map.map[*i]);
    }
    return digit_from_segments(mapped_segments);
  }
};

struct Line {
  vector<BrokenDigit> input;
  vector<BrokenDigit> output;

  optional<SegmentMap> generate_segment_map() {
    vector<SegmentMap> all_maps = all_possible_segment_maps();
    vector<BrokenDigit> broken_digits_to_guess;
    broken_digits_to_guess.insert(broken_digits_to_guess.end(), input.begin(), input.end());
    broken_digits_to_guess.insert(broken_digits_to_guess.end(), output.begin(), output.end());
    auto broken_digits_to_guess_size = broken_digits_to_guess.size();
    for (auto m = all_maps.begin(); m != all_maps.end(); ++m) {
      int matches = 0;
      for (auto d = broken_digits_to_guess.begin(); d != broken_digits_to_guess.end(); ++d) {
        if (d->to_digit(*m).has_value())
          matches++;
      }
      if (matches == broken_digits_to_guess_size) {
        return *m;
      }
    }
    return nullopt;
  }
};

// MARK: - Parsers

vector<string> split(string str, string token) {
  vector<string> result;
  while (str.size()) {
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

optional<Segment> parse_segment(char input) {
  if (input == 'a') {
    return Segment::a;
  } else if (input == 'b') {
    return Segment::b;
  } else if (input == 'c') {
    return Segment::c;
  } else if (input == 'd') {
    return Segment::d;
  } else if (input == 'e') {
    return Segment::e;
  } else if (input == 'f') {
    return Segment::f;
  } else if (input == 'g') {
    return Segment::g;
  }
  return nullopt;
}

BrokenDigit parse_digit(string input) {
  vector<Segment> segments;
  for (auto i = input.begin(); i != input.end(); ++i) {
    optional<Segment> parsed_segment = parse_segment(*i);
    if (parsed_segment.has_value()) {
      segments.push_back(*parsed_segment);
    }
  }
  return BrokenDigit{segments};
}

vector<BrokenDigit> parse_digits(string input) {
  vector<string> digits_strings = split(input, " ");
  vector<BrokenDigit> digits;
  for (auto i = digits_strings.begin(); i != digits_strings.end(); ++i) {
    digits.push_back(parse_digit(*i));
  }
  return digits;
}

Line parse_line(string input) {
  vector<string> components = split(input, " | ");
  return Line{parse_digits(components[0]), parse_digits(components[1])};
}

// MARK: - Parts 1 & 2

int part1(vector<vector<Digit>> output) {
  int count = 0;
  for (auto i = output.begin(); i != output.end(); ++i) {
    for (auto d = i->begin(); d != i->end(); ++d) {
      if (*d == Digit::one || *d == Digit::four || *d == Digit::seven || *d == Digit::eight) {
        count++;
      }
    }
  }
  return count;
}

int part2(vector<vector<Digit>> output) {
  int sum = 0;
  for (auto i = output.begin(); i != output.end(); ++i) {
    int current_sum = 0;
    for (auto d = i->begin(); d != i->end(); ++d) {
      current_sum *= 10;
      current_sum += *d;
    }
    sum += current_sum;
  }
  return sum;
}

int main() {
  // MARK: - Read Input

  ifstream is("input.txt");
  string str;
  vector<Line> parsed_input;
  while(getline(is, str)) {
    parsed_input.push_back(parse_line(str));
  }

  vector<vector<Digit>> corrected_output;

  for (auto line = parsed_input.begin(); line != parsed_input.end(); ++line) {
    optional<SegmentMap> segment_map = line->generate_segment_map();
    if (segment_map.has_value()) {
      vector<Digit> corrected_digits;
      for (auto o = line->output.begin(); o != line->output.end(); ++o) {
        optional<Digit> corrected_digit = o->to_digit(*segment_map);
        if (corrected_digit.has_value()) {
          corrected_digits.push_back(*corrected_digit);
        }
      }
      corrected_output.push_back(corrected_digits);
    }
  }

  cout << "Part 1: " << part1(corrected_output) << endl;
  cout << "Part 2: " << part2(corrected_output) << endl;
  return 0;
}
