#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <vector>
using namespace std;

// MARK: - Fish Counting

map<int, uint64_t> cached_count_at_age_zero_for_day = {};

uint64_t fish_count(int age, int days) {
  if (days <= age) {
    return 1;
  } else if (age != 0) {
    return fish_count(0, days - age);
  }

  if (cached_count_at_age_zero_for_day.count(days)) {
    return cached_count_at_age_zero_for_day[days];
  }

  uint64_t count = fish_count(7, days) + fish_count(9, days);
  cached_count_at_age_zero_for_day[days] = count;
  return count;
}

uint64_t fish_after_days(int days, vector<int> initial_state) {
  uint64_t result = 0;
  for (auto i = initial_state.begin(); i != initial_state.end(); ++i) {
    int age = *i;
    result += fish_count(age, days);
  }
  return result;
}

void print_fish_count(int days, vector<int> initial_state) {
  uint64_t fish_count = fish_after_days(days, initial_state);
  cout << fish_count << " lantern fish after " << days << " days" << endl;
}

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

int main() {
  // MARK: - Read Input

  ifstream is("input.txt");
  string str;
  vector<int> initial_state;
  while(getline(is, str)) {
    if (initial_state.empty()) {
      vector<string> initial_state_str = split(str, ",");
      for (auto i = initial_state_str.begin(); i != initial_state_str.end(); ++i)
      {
        initial_state.push_back(stoi(*i));
      }
      continue;
    } else {
      continue;
    }
  }

  print_fish_count(80, initial_state);
  print_fish_count(256, initial_state);

  return 0;
}
