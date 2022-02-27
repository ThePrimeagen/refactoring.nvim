#include <iostream>

class Coconut {

void foo(INSERT_PARAM_TYPE a, INSERT_PARAM_TYPE test, INSERT_PARAM_TYPE test_other) {
    for (int x = 0; x < test_other + test; x++) {
      std::cout << x << " " << a << std::endl;
    }
}


  void simpleFunction(int a) {
    int test = 1, test_other = 11;
    foo(a, test, test_other);

  }
};
