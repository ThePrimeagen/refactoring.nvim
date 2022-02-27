#include <stdio.h>

int foo() {
  int i = 3;
  printf("%d", i);
  return i;
}


int simple_function(int a) {
  printf("this is a test\n");
  auto i = foo();


  return i;
}
