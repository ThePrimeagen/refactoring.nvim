#include <iostream>

class Coconut {

void foo(int a, int test, int test_other) {
    for (int x = 0; x < test_other + test; x++) {
      std::cout << x << " " << a << std::endl;
    }
}


  void simpleFunction(int a) {
    int test = 1, test_other = 11;
    foo(a, test, test_other);
  }
};
