#include <stdio.h>

class Test {
    public:
        ~Test() {

// __AUTO_GENERATED_PRINTF_START__
printf("Test#~Test 1(%d): \n", __LINE__); // __AUTO_GENERATED_PRINTF_END__
        }
};

