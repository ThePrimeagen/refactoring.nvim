#include <stdio.h>

void foo_bar(INSERT_VAR_TYPE a, INSERT_VAR_TYPE test, INSERT_VAR_TYPE test_other) {
      for (int idx = test - 1; idx < test_other; idx++) {
    printf("%d %d", idx, a);
  }
}


void simple_function(int a) {
  int test = 1, test_other = 1;

foo_bar(a, test, test_other);

}
