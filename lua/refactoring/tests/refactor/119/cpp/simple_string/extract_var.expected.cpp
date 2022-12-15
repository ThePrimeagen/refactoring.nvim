#include <algorithm>
#include <iostream>
#include <string>

struct Person {
  std::string firstName;
  std::string lastName;
};

std::string orderCalculation(Person person, std::string start, std::string end) {
  auto foo_bar = " [space] ";
  std::string greeting = start + foo_bar + end;

  std::cout << greeting << std::endl;

  return start + person.firstName + foo_bar + person.lastName + end;
}
