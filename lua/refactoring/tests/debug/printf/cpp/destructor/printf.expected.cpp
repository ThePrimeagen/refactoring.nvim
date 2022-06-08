#include <stdio.h>

class Test {
    public:
        ~Test() {

printf("Test#~Test(%d): \n", __LINE__);// __AUTO_GENERATED_PRINTF__
        }
};

