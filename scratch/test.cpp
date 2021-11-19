#include <stdio.h>

class Test {
    public:
        ~Test() {
printf("Test# \n");
printf("Test#~Test \n");

        }
        void foo();
        void* foo2();
        void* foo3() {
printf("Test#foo3 \n");
printf("Test#foo3 \n");
           return 0x0;
        }
};

void Test::foo() {
printf(" \n");
printf("Test::foo \n");

}

void *Test::foo2() {
printf("Test::foo2 \n");
printf(" \n");

}
