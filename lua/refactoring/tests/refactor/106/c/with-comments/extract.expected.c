#include <stdio.h>

void foo_bar(INSERT_PARAM_TYPE a, INSERT_PARAM_TYPE test, INSERT_PARAM_TYPE test_other) {
      for (int idx = test - 1; idx < test_other; idx++) {
    printf("%d %d", idx, a);
  }
}


/*
 * This is a comment
 * comments are fun
 * wow!
 */
void simple_function(int a) {
  int test = 1, test_other = 1;

foo_bar(a, test, test_other);

}
