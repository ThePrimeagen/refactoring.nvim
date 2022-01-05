#include <stdio.h>

/*
 * This is a comment
 * comments are fun
 * wow!
 */
void simple_function(int a) {
  int test = 1, test_other = 1;

  for (int idx = test - 1; idx < test_other; idx++) {
    printf("%d %d", idx, a);
  }
}
