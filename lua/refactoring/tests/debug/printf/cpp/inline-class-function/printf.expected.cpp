#include <stdio.h>

class Test {
    public:
        ~Test() { }
        void foo() {

// __AUTO_GENERATED_PRINTF_START__
printf("Test#foo 1(%d): \n", __LINE__); // __AUTO_GENERATED_PRINTF_END__
        }
};

