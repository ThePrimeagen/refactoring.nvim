#include <stdio.h>

void foo_bar(int a) {
  int test = 1, test_other = 1;

  for (int idx = test - 1; idx < test_other; idx++) {
    printf("%d %d", idx, a);
  }
}


void simple_function(int a) {
  foo_bar(a);
}
