#include <stdio.h>

class Test {
    public:
        ~Test() { }
        void foo();
};

void Test::foo() {

printf("Test::foo 1(%d): \n", __LINE__); // __AUTO_GENERATED_PRINTF__
}
