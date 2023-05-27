#include <iostream>

void foo_bar(int a) {
  int test = 1, test_other = 1;

  for (int idx = test - 1; idx < test_other; idx++) {
    std::cout << idx << " " << a << std::endl;
  }
}


void simple_function(int a) {
  foo_bar(a);
}
