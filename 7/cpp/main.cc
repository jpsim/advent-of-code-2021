#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <vector>
using namespace std;

// MARK: - Cost Functions

int median(vector<int> input) {
  sort(input.begin(), input.end());
  return input[input.size() / 2];
}

int part1_cost(vector<int> input, int destination) {
  int cost = 0;
  for (auto i = input.begin(); i != input.end(); ++i) {
    cost += abs(*i - destination);
  }
  return cost;
}

int part2_cost(int origin, int destination) {
  int cost = 0;
  for (int i = 1; i <= abs(origin - destination); ++i) {
    cost += i;
  }
  return cost;
}

int part2_cost(vector<int> input, int destination) {
  int cost = 0;
  for (auto i = input.begin(); i != input.end(); ++i) {
    cost += part2_cost(*i, destination);
  }
  return cost;
}

int part2_cost(vector<int> input) {
  int min = *min_element(input.begin(), input.end());
  int max = *max_element(input.begin(), input.end());
  int cost = INT_MAX;
  for (int m = min; m <= max; ++m) {
    int current_cost = part2_cost(input, m);
    if (current_cost < cost)
      cost = current_cost;
  }
  return cost;
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
    }
  }

  int part1 = part1_cost(initial_state, median(initial_state));
  cout << "Part 1: " << part1 << endl;
  int part2 = part2_cost(initial_state);
  cout << "Part 2: " << part2 << endl;
  return 0;
}
