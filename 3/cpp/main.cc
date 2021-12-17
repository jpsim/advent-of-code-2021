#include <iostream>
#include <fstream>
#include <string>
#include <vector>
using namespace std;

// MARK: - Most Common Bit

bool most_common_bit(vector<bool> bits) {
  int true_count = 0;
  for (auto i = bits.begin(); i != bits.end(); ++i)
  {
    true_count += (*i ? 1 : 0);
  }

  int false_count = bits.size() - true_count;
  return true_count >= false_count;
}

// MARK: Bits To Int

int bits_to_int(vector<bool> bits) {
  int result = 0;
  for (auto i = bits.begin(); i != bits.end(); ++i)
  {
    result = result << 1;
    result += (*i ? 1 : 0);
  }
  return result;
}

// MARK: - Get Gamma

int get_gamma(vector<vector<bool>> bits) {
  int number_of_bits = bits[0].size();
  vector<bool> most_common_bits;
  for (int bit_index = 0; bit_index < number_of_bits; ++bit_index)
  {
    vector<bool> bits_at_index;
    for (auto i = bits.begin(); i != bits.end(); ++i)
    {
      vector<bool> bits_line = *i;
      bits_at_index.push_back(bits_line[bit_index]);
    }
    most_common_bits.push_back(most_common_bit(bits_at_index));
  }
  return bits_to_int(most_common_bits);
}

// MARK: - Get Epsilon

int get_epsilon(vector<vector<bool>> bits) {
  int number_of_bits = bits[0].size();
  vector<bool> least_common_bits;
  for (int bit_index = 0; bit_index < number_of_bits; ++bit_index)
  {
    vector<bool> bits_at_index;
    for (auto i = bits.begin(); i != bits.end(); ++i)
    {
      vector<bool> bits_line = *i;
      bits_at_index.push_back(bits_line[bit_index]);
    }
    least_common_bits.push_back(!most_common_bit(bits_at_index));
  }
  return bits_to_int(least_common_bits);
}

// MARK: - Get Oxygen Generator Rating

int get_oxygen_generator_rating(vector<vector<bool>> bits) {
  int number_of_bits = bits[0].size();
  vector<vector<bool>> shrinking_bits = bits;
  for (int bit_index = 0; bit_index < number_of_bits; ++bit_index)
  {
    vector<bool> bits_at_index;
    for (auto i = shrinking_bits.begin(); i != shrinking_bits.end(); ++i)
    {
      vector<bool> bits_line = *i;
      bits_at_index.push_back(bits_line[bit_index]);
    }
    bool most_common = most_common_bit(bits_at_index);

    vector<vector<bool>> new_shrinking_bits;
    for (auto i = shrinking_bits.begin(); i != shrinking_bits.end(); ++i)
    {
      vector<bool> bits_line = *i;
      bool bit_at_index = bits_line[bit_index];
      if (bit_at_index == most_common) {
        new_shrinking_bits.push_back(*i);
      }
    }
    shrinking_bits = new_shrinking_bits;
  }
  return bits_to_int(shrinking_bits[0]);
}

// MARK: - Get CO2 Scrubber Rating

int get_co2_scrubber_rating(vector<vector<bool>> bits) {
  int number_of_bits = bits[0].size();
  vector<vector<bool>> shrinking_bits = bits;
  for (int bit_index = 0; bit_index < number_of_bits; ++bit_index)
  {
    vector<bool> bits_at_index;
    for (auto i = shrinking_bits.begin(); i != shrinking_bits.end(); ++i)
    {
      vector<bool> bits_line = *i;
      bits_at_index.push_back(bits_line[bit_index]);
    }
    bool least_common = !most_common_bit(bits_at_index);

    vector<vector<bool>> new_shrinking_bits;
    for (auto i = shrinking_bits.begin(); i != shrinking_bits.end(); ++i)
    {
      vector<bool> bits_line = *i;
      bool bit_at_index = bits_line[bit_index];
      if (bit_at_index == least_common) {
        new_shrinking_bits.push_back(*i);
      }
    }
    shrinking_bits = new_shrinking_bits;
    if (shrinking_bits.size() == 1) {
      break;
    }
  }
  return bits_to_int(shrinking_bits[0]);
}

int main() {
  // MARK: - Read Input

  ifstream is("input.txt");
  vector<vector<bool>> bits;
  string str_bits;
  while(getline(is, str_bits)) {
    vector<bool> line_bits;
    for (auto i = str_bits.begin(); i != str_bits.end(); ++i)
    {
      line_bits.push_back(*i == '1');
    }
    bits.push_back(line_bits);
  }

  // MARK: - Part 1

  {
    cout << "# Part 1" << endl;
    int gamma = get_gamma(bits);
    cout << "gamma: " << gamma << endl;
    int epsilon = get_epsilon(bits);
    cout << "epsilon: " << epsilon << endl;
    int power_consumption = gamma * epsilon;
    cout << "power consumption: " << power_consumption << endl;
  }

  // MARK: - Part 2

  {
    cout << "# Part 2" << endl;
    int oxygen_generator_rating = get_oxygen_generator_rating(bits);
    cout << "oxygen generator rating: " << oxygen_generator_rating << endl;
    int co2_scrubber_rating = get_co2_scrubber_rating(bits);
    cout << "CO2 scrubber rating: " << co2_scrubber_rating << endl;
    int life_support_rating = oxygen_generator_rating * co2_scrubber_rating;
    cout << "life support rating: " << life_support_rating << endl;
  }

  return 0;
}
