#include <stdio.h>

class Test {
    public:
        ~Test() {
            printf("");
            // __AUTO_GENERATED_PRINTF_START__
            printf("Test#~Test 1(%d): \n", __LINE__); // __AUTO_GENERATED_PRINTF_END__
        }
};

