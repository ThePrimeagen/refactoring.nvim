#include <stdio.h>

int simple_function(int a) {
  int test = 1;
  int test_other = 1;

  for (int i = 0; i < test_other; i++) {
    printf("%d %d", a, test_other);
  }

  return test;
}
