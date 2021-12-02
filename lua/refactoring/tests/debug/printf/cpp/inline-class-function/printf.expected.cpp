#include <stdio.h>

class Test {
    public:
        ~Test() { }
        void foo() {

printf("Test#foo(%d): \n", __LINE__);
        }
};

