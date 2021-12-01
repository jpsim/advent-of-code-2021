#include <iostream>
#include <fstream>
#include <string>
#include <vector>
using namespace std;

struct Window {
  vector<int> members;

  int sum() const {
    int result = 0;
    for (auto i = members.begin(); i != members.end(); ++i) {
      result += *i;
    }
    return result;
  }
};

int main() {
  // MARK: - Part 1

  cout << "# Part 1" << endl;

  ifstream is("input.txt");
  string str;

  int last_number = INT_MAX;
  int increases = 0;
  vector<int> numbers;
  while(getline(is, str)) {
    int number = stoi(str);
    numbers.push_back(number);
    if (number > last_number) {
      increases++;
    }
    last_number = number;
  }

  cout << "Increases: " << increases << endl;

  // MARK: - Part 2

  cout << "# Part 2" << endl;

  vector<Window> windows_of_three = {};
  int windows_of_three_increases = 0;

  for (auto i = numbers.begin(); i != numbers.end() - 2; ++i) {
    Window window = Window();
    window.members = {*i, *(i + 1), *(i + 2)};
    windows_of_three.push_back(window);
  }

  for (auto i = windows_of_three.begin(); i != windows_of_three.end(); ++i) {
    if (i->sum() < (i+1)->sum()) {
      windows_of_three_increases++;
    }
  }

  cout << "Windows of 3 increases: " << windows_of_three_increases << endl;
  return 0;
}
