#include <algorithm>
#include <iostream>
#include <string>

struct Person {
  std::string firstName;
  std::string lastName;
};

std::string orderCalculation(Person person, std::string start, std::string end) {
  auto space = " [space] ";
  std::string greeting = start + space + end;

  std::cout << greeting << std::endl;
  std::cout << " [not space] " << std::endl;

  return start + person.firstName + space + person.lastName + end;
}
