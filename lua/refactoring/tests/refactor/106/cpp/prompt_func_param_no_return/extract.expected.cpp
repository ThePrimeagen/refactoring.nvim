#include <stdio.h>

void foo(int a) {
  int test_other = 1;

  for (int idx = 0; idx < test_other; idx++) {
    printf("%d %d", idx, a);
  }
}


void simple_function(int a) {
  int test = 1;
  foo(a);
}
