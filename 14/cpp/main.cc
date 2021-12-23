#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <vector>
using namespace std;

// MARK: - BigInt

// From: https://www.geeksforgeeks.org/bigint-big-integers-in-c-with-example/

class BigInt {
    string digits;
public:

    //Constructors:
    BigInt(unsigned long long n = 0);
    BigInt(string &);
    BigInt(const char *);
    BigInt(const BigInt&);

    //Helper Functions:
    friend bool Null(const BigInt &);
    friend int Lenght(const BigInt &);
    int operator[](const int)const;

               /* * * * Operator Overloading * * * */

    //Direct assignment
    BigInt &operator=(const BigInt &);

    //Post/Pre - Incrementation
    BigInt &operator++();
    BigInt operator++(int temp);
    BigInt &operator--();
    BigInt operator--(int temp);

    //Addition and Subtraction
    friend BigInt &operator+=(BigInt &, const BigInt &);
    friend BigInt operator+(const BigInt &, const BigInt &);
    friend BigInt operator-(const BigInt &, const BigInt &);
    friend BigInt &operator-=(BigInt &, const BigInt &);

    //Comparison operators
    friend bool operator==(const BigInt &, const BigInt &);
    friend bool operator!=(const BigInt &, const BigInt &);

    friend bool operator>(const BigInt &, const BigInt &);
    friend bool operator>=(const BigInt &, const BigInt &);
    friend bool operator<(const BigInt &, const BigInt &);
    friend bool operator<=(const BigInt &, const BigInt &);

    //Multiplication and Division
    friend BigInt &operator*=(BigInt &, const BigInt &);
    friend BigInt operator*(const BigInt &, const BigInt &);
    friend BigInt &operator/=(BigInt &, const BigInt &);
    friend BigInt operator/(const BigInt &, const BigInt &);

    //Read and Write
    friend ostream &operator<<(ostream &,const BigInt &);
};

BigInt::BigInt(string & s){
    digits = "";
    int n = s.size();
    for (int i = n - 1; i >= 0;i--){
        if(!isdigit(s[i]))
            throw("ERROR");
        digits.push_back(s[i] - '0');
    }
}
BigInt::BigInt(unsigned long long nr){
    do{
        digits.push_back(nr % 10);
        nr /= 10;
    } while (nr);
}
BigInt::BigInt(const char *s){
    digits = "";
    for (int i = strlen(s) - 1; i >= 0;i--)
    {
        if(!isdigit(s[i]))
            throw("ERROR");
        digits.push_back(s[i] - '0');
    }
}
BigInt::BigInt(const BigInt& a){
    digits = a.digits;
}

bool Null(const BigInt& a){
    if(a.digits.size() == 1 && a.digits[0] == 0)
        return true;
    return false;
}
int Lenght(const BigInt & a){
    return a.digits.size();
}
int BigInt::operator[](const int index)const{
    if(digits.size() <= index || index < 0)
        throw("ERROR");
    return digits[index];
}
bool operator==(const BigInt &a, const BigInt &b){
    return a.digits == b.digits;
}
bool operator!=(const BigInt & a,const BigInt &b){
    return !(a == b);
}
bool operator<(const BigInt&a,const BigInt&b){
    int n = Lenght(a), m = Lenght(b);
    if(n != m)
        return n < m;
    while(n--)
        if(a.digits[n] != b.digits[n])
            return a.digits[n] < b.digits[n];
    return false;
}
bool operator>(const BigInt&a,const BigInt&b){
    return b < a;
}
bool operator>=(const BigInt&a,const BigInt&b){
    return !(a < b);
}
bool operator<=(const BigInt&a,const BigInt&b){
    return !(a > b);
}

BigInt &BigInt::operator=(const BigInt &a){
    digits = a.digits;
    return *this;
}

BigInt &BigInt::operator++(){
    int i, n = digits.size();
    for (i = 0; i < n && digits[i] == 9;i++)
        digits[i] = 0;
    if(i == n)
        digits.push_back(1);
    else
        digits[i]++;
    return *this;
}
BigInt BigInt::operator++(int temp){
    BigInt aux;
    aux = *this;
    ++(*this);
    return aux;
}

BigInt &BigInt::operator--(){
    if(digits[0] == 0 && digits.size() == 1)
        throw("UNDERFLOW");
    int i, n = digits.size();
    for (i = 0; digits[i] == 0 && i < n;i++)
        digits[i] = 9;
    digits[i]--;
    if(n > 1 && digits[n - 1] == 0)
        digits.pop_back();
    return *this;
}
BigInt BigInt::operator--(int temp){
    BigInt aux;
    aux = *this;
    --(*this);
    return aux;
}

BigInt &operator+=(BigInt &a,const BigInt& b){
    int t = 0, s, i;
    int n = Lenght(a), m = Lenght(b);
    if(m > n)
        a.digits.append(m - n, 0);
    n = Lenght(a);
    for (i = 0; i < n;i++){
        if(i < m)
            s = (a.digits[i] + b.digits[i]) + t;
        else
            s = a.digits[i] + t;
        t = s / 10;
        a.digits[i] = (s % 10);
    }
    if(t)
        a.digits.push_back(t);
    return a;
}
BigInt operator+(const BigInt &a, const BigInt &b){
    BigInt temp;
    temp = a;
    temp += b;
    return temp;
}

BigInt &operator-=(BigInt&a,const BigInt &b){
    if(a < b)
        throw("UNDERFLOW");
    int n = Lenght(a), m = Lenght(b);
    int i, t = 0, s;
    for (i = 0; i < n;i++){
        if(i < m)
            s = a.digits[i] - b.digits[i]+ t;
        else
            s = a.digits[i]+ t;
        if(s < 0)
            s += 10,
            t = -1;
        else
            t = 0;
        a.digits[i] = s;
    }
    while(n > 1 && a.digits[n - 1] == 0)
        a.digits.pop_back(),
        n--;
    return a;
}
BigInt operator-(const BigInt& a,const BigInt&b){
    BigInt temp;
    temp = a;
    temp -= b;
    return temp;
}

BigInt &operator*=(BigInt &a, const BigInt &b)
{
    if(Null(a) || Null(b)){
        a = BigInt();
        return a;
    }
    int n = a.digits.size(), m = b.digits.size();
    vector<int> v(n + m, 0);
    for (int i = 0; i < n;i++)
        for (int j = 0; j < m;j++){
            v[i + j] += (a.digits[i] ) * (b.digits[j]);
        }
    n += m;
    a.digits.resize(v.size());
    for (int s, i = 0, t = 0; i < n; i++)
    {
        s = t + v[i];
        v[i] = s % 10;
        t = s / 10;
        a.digits[i] = v[i] ;
    }
    for (int i = n - 1; i >= 1 && !v[i];i--)
            a.digits.pop_back();
    return a;
}
BigInt operator*(const BigInt&a,const BigInt&b){
    BigInt temp;
    temp = a;
    temp *= b;
    return temp;
}

BigInt &operator/=(BigInt& a,const BigInt &b){
    if(Null(b))
        throw("Arithmetic Error: Division By 0");
    if(a < b){
        a = BigInt();
        return a;
    }
    if(a == b){
        a = BigInt(1);
        return a;
    }
    int i, lgcat = 0, cc;
    int n = Lenght(a), m = Lenght(b);
    vector<int> cat(n, 0);
    BigInt t;
    for (i = n - 1; t * 10 + a.digits[i]  < b;i--){
        t *= 10;
        t += a.digits[i] ;
    }
    for (; i >= 0; i--){
        t = t * 10 + a.digits[i];
        for (cc = 9; cc * b > t;cc--);
        t -= cc * b;
        cat[lgcat++] = cc;
    }
    a.digits.resize(cat.size());
    for (i = 0; i < lgcat;i++)
        a.digits[i] = cat[lgcat - i - 1];
    a.digits.resize(lgcat);
    return a;
}

BigInt operator/(const BigInt &a,const BigInt &b){
    BigInt temp;
    temp = a;
    temp /= b;
    return temp;
}

ostream &operator<<(ostream &out,const BigInt &a){
    for (int i = a.digits.size() - 1; i >= 0;i--)
        cout << (short)a.digits[i];
    return cout;
}

// MARK: - Models

struct CharacterPair {
  char first;
  char second;

  bool operator ==(const CharacterPair& rhs) const {
    return first == rhs.first
      && second == rhs.second;
  }

  bool operator <(const CharacterPair& rhs) const {
    return first < rhs.first ||
      (first == rhs.first && second < rhs.second);
  }
};

struct TemplatePair {
  CharacterPair characters;
  bool at_start;
  bool at_end;

  bool on_edge() {
    return at_start || at_end;
  }

  bool operator ==(const TemplatePair& rhs) const {
    return characters == rhs.characters
      && at_start == rhs.at_start
      && at_end == rhs.at_end;
  }

  bool operator <(const TemplatePair& rhs) const {
    return characters < rhs.characters ||
      (characters == rhs.characters && at_start < rhs.at_start) ||
      (characters == rhs.characters && at_start == rhs.at_start && at_end < rhs.at_end);
  }
};

struct Rule {
  CharacterPair input;
  char output;
};

struct Rules {
  map<CharacterPair, char> rules;

  Rules(const vector<Rule>& vec) {
    for (auto r = vec.begin(); r != vec.end(); ++r)
      rules[r->input] = r->output;
  }

  optional<char> output(CharacterPair pair) {
    if (rules.count(pair))
      return rules[pair];
    return nullopt;
  }
};

struct Template {
  map<TemplatePair, BigInt> pairs;

  void advance(Rules rules) {
    map<TemplatePair, BigInt> new_pairs;
    for (auto i = pairs.begin(); i != pairs.end(); ++i) {
      TemplatePair pair = i->first;
      BigInt count = i->second;
      optional<char> insertion = rules.output(pair.characters);
      if (!insertion.has_value()) {
        new_pairs[pair] += count;
        continue;
      }

      TemplatePair starting({{pair.characters.first, *insertion}, pair.at_start, false});
      new_pairs[starting] += count;
      TemplatePair ending({{*insertion, pair.characters.second}, false, pair.at_end});
      new_pairs[ending] += count;
    }
    pairs = new_pairs;
  }

  BigInt score() {
    map<char, BigInt> counts;
    for (auto i = pairs.begin(); i != pairs.end(); ++i) {
      TemplatePair pair = i->first;
      if (pair.on_edge())
        continue;

      BigInt count = i->second;
      counts[pair.characters.first] += count;
      counts[pair.characters.second] += count;
    }

    // middle values are double counted because adjacent pairs overlap
    for (auto i = counts.begin(); i != counts.end(); ++i)
      counts[i->first] = i->second / 2;

    for (auto i = pairs.begin(); i != pairs.end(); ++i) {
      TemplatePair pair = i->first;
      if (!pair.on_edge())
        continue;

      BigInt count = i->second;
      counts[pair.characters.first] += count;
      counts[pair.characters.second] += count;
    }

    optional<BigInt> max_value;
    optional<BigInt> min_value;
    for (auto i = counts.begin(); i != counts.end(); ++i) {
      BigInt count = i->second;
      if (!max_value.has_value())
        max_value = count;
      else
        max_value = max(*max_value, count);

      if (!min_value.has_value())
        min_value = count;
      else
        min_value = min(*min_value, count);
    }

    return *max_value - *min_value;
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

Template parse_template(string str) {
  map<TemplatePair, BigInt> pairs;
  for (int i = 0; i < str.size() - 1; ++i) {
    CharacterPair characters = {str[i], str[i + 1]};
    TemplatePair pair = {characters, i == 0, i == str.size() - 2};
    pairs[pair]++;
  }
  return {pairs};
}

Rule parse_rule(string input) {
  vector<string> rule_components = split(input, " -> ");
  return {{rule_components[0][0], rule_components[0][1]}, rule_components[1][0]};
}

// MARK: - Parts 1 & 2

BigInt score_after(int steps, Template my_template, Rules rules) {
  for (int i = 0; i < steps; ++i)
    my_template.advance(rules);
  return my_template.score();
}

BigInt part1(Template my_template, Rules rules) {
  return score_after(10, my_template, rules);
}

BigInt part2(Template my_template, Rules rules) {
  return score_after(40, my_template, rules);
}

int main() {
  // MARK: - Read Input

  ifstream is("input.txt");
  string str;
  optional<string> template_str;
  vector<Rule> parsed_rules;
  while(getline(is, str)) {
    if (!template_str.has_value())
      template_str = {str};
    else if (!str.empty())
      parsed_rules.push_back(parse_rule(str));
  }

  Template my_template = parse_template(*template_str);
  Rules rules({parsed_rules});
  cout << "Part 1: " << part1(my_template, rules) << endl;
  cout << "Part 2: " << part2(my_template, rules) << endl;
  return 0;
}
