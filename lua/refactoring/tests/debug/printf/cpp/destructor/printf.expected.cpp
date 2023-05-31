#include <stdio.h>

class Test {
    public:
        ~Test() {

        printf("Test#~Test 1(%d): \n", __LINE__); // __AUTO_GENERATED_PRINTF__
        }
};

