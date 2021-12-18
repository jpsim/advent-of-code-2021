#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>
using namespace std;

// MARK: - Models

struct BingoBoard {
  vector<vector<int>> rows;
  vector<int> called_numbers;

  void call(int number) {
    called_numbers.push_back(number);
  }

  vector<vector<int>> columns() {
    vector<vector<int>> columns;
    for (int column_index = 0; column_index < 5; ++column_index)
    {
      vector<int> column;
      for (auto i = rows.begin(); i != rows.end(); ++i)
      {
        vector<int> row = *i;
        column.push_back(row[column_index]);
      }
      columns.push_back(column);
    }
    return columns;
  }

  bool did_win() {
    for (auto i = rows.begin(); i != rows.end(); ++i)
    {
      int matches = 0;
      for (auto n = called_numbers.begin(); n != called_numbers.end(); ++n)
      {
        if (count(i->begin(), i->end(), *n) > 0)
          matches++;
      }
      if (matches == 5)
        return true;
    }

    vector<vector<int>> cols = columns();
    for (auto i = cols.begin(); i != cols.end(); ++i)
    {
      int matches = 0;
      for (auto n = called_numbers.begin(); n != called_numbers.end(); ++n)
      {
        if (count(i->begin(), i->end(), *n) > 0)
          matches++;
      }
      if (matches == 5)
        return true;
    }

    return false;
  }

  int unmarked_sum() {
    int sum = 0;

    for (auto r = rows.begin(); r != rows.end(); ++r)
    {
      for (auto c = r->begin(); c != r->end(); ++c)
      {
        if (count(called_numbers.begin(), called_numbers.end(), *c) == 0)
          sum += *c;
      }
    }

    return sum;
  }
};

// MARK: - Get Scores

pair<int, int> get_scores(vector<BingoBoard>& boards, vector<int> called_numbers) {
  int first = 0;
  vector<int> winning_boards;
  for (auto n = called_numbers.begin(); n != called_numbers.end(); ++n)
  {
    for (int board_index = 0; board_index < boards.size(); ++board_index)
    {
      if (count(winning_boards.begin(), winning_boards.end(), board_index) > 0)
      {
        continue;
      }

      BingoBoard& board = boards[board_index];
      board.call(*n);
      if (board.did_win()) {
        winning_boards.push_back(board_index);
        if (winning_boards.size() == 1) {
          first = *n * board.unmarked_sum();
        } else if (winning_boards.size() == boards.size()) {
          return {first, *n * board.unmarked_sum()};
        }
      }
    }
  }

  cout << "Not all boards won" << endl;
  abort();
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
  vector<BingoBoard> boards;
  vector<int> called_numbers;
  vector<string> next_board_lines;
  while(getline(is, str)) {
    // MARK: - Parse Called Numbers
    if (called_numbers.empty()) {
      vector<string> called_numbers_str = split(str, ",");
      for (auto i = called_numbers_str.begin(); i != called_numbers_str.end(); ++i)
      {
        called_numbers.push_back(stoi(*i));
      }
      continue;
    } else if (str.empty()) {
      continue;
    }

    // MARK: - Parse Bingo Boards

    next_board_lines.push_back(str);
    if (next_board_lines.size() == 5) {
      BingoBoard board;
      for (auto i = next_board_lines.begin(); i != next_board_lines.end(); ++i)
      {
        stringstream stream(*i);
        int number;
        vector<int> numbers;
        while (stream >> number) {
          numbers.push_back(number);
        }
        board.rows.push_back(numbers);
      }
      
      boards.push_back(board);
      next_board_lines.clear();
    }
  }

  // MARK: - Parts 1 & 2

  pair<int, int> scores = get_scores(boards, called_numbers);
  int first = scores.first;
  cout << "first score: " << first << endl;
  int last = scores.second;
  cout << "last score: " << last << endl;
  return 0;
}
