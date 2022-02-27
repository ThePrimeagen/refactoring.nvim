#include <stdio.h>

int foo(int a) {
  int i = 3;
  printf("%d %d", i, a);
  return i;
}


int simple_function(int a) {
  printf("this is a test\n");
  INSERT_TYPE_HERE i = foo(a);


  return i;
}
