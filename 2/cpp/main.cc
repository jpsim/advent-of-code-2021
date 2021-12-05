#include <iostream>
#include <fstream>
#include <string>
#include <vector>
using namespace std;

enum RawCommand { forward, down, up };

struct Command {
  RawCommand raw_command;
  int amount;

  int position() {
    switch (raw_command) {
    case RawCommand::forward:
      return amount;
    case RawCommand::down:
      return 0;
    case RawCommand::up:
      return 0;
    }
  }

  int depth() {
    switch (raw_command) {
    case RawCommand::forward:
      return 0;
    case RawCommand::down:
      return amount;
    case RawCommand::up:
      return -amount;
    }
  }
};

int main() {
  ifstream is("input.txt");
  string str_command;

  vector<Command> commands;
  while(getline(is, str_command)) {
    string forward = "forward ";
    string down = "down ";
    string up = "up ";

    if (str_command.compare(0, forward.size(), forward) == 0) {
      Command command;
      command.raw_command = RawCommand::forward;
      int amount = stoi(str_command.substr(forward.size()));
      command.amount = amount;
      commands.push_back(command);
    } else if (str_command.compare(0, down.size(), down) == 0) {
      Command command;
      command.raw_command = RawCommand::down;
      int amount = stoi(str_command.substr(down.size()));
      command.amount = amount;
      commands.push_back(command);
    } else if (str_command.compare(0, up.size(), up) == 0) {
      Command command;
      command.raw_command = RawCommand::up;
      int amount = stoi(str_command.substr(up.size()));
      command.amount = amount;
      commands.push_back(command);
    }
  }

  {
    cout << "# Part 1" << endl;

    int position = 0;
    int depth = 0;

    for (auto i = commands.begin(); i != commands.end(); ++i) {
      position += i->position();
      depth += i->depth();
    }

    cout << "Position: " << position << endl;
    cout << "Depth: " << depth << endl;
    cout << "Multiplied: " << position * depth << endl;
  }

  {
    cout << "# Part 2" << endl;

    int position = 0;
    int depth = 0;
    int aim = 0;

    for (auto i = commands.begin(); i != commands.end(); ++i) {
      position += i->position();
      aim += i->depth();
      depth += i->position() * aim;
    }

    cout << "Position: " << position << endl;
    cout << "Depth: " << depth << endl;
    cout << "Multiplied: " << position * depth << endl;
  }
  return 0;
}
