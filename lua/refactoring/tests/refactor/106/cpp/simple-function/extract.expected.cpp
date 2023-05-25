#include <iostream>

void foo_bar(int a, INSERT_PARAM_TYPE test, INSERT_PARAM_TYPE test_other) {
  for (int idx = test - 1; idx < test_other; idx++) {
    std::cout << idx << " " << a << std::endl;
  }
}


void simple_function(int a) {
  int test = 1, test_other = 1;

  foo_bar(a, test, test_other);
}
