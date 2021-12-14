#include <iostream>

class Coconut {

  void simpleFunction(int a) {
    int test = 1, test_other = 11;
    for (int x = 0; x < test_other + test; x++) {
      std::cout << x << " " << a << std::endl;
    }
  }
};
