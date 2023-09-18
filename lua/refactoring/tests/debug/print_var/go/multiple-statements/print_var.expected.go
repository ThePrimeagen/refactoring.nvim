package main

import "fmt"

func simple_function(a int) {
    var test int = 1
    test_other := 1
    // __AUTO_GENERATED_PRINT_VAR_START__
    fmt.Println(fmt.Sprintf("custom print var simple_function test_other:: %v", test_other)) // __AUTO_GENERATED_PRINT_VAR_END__
    for idx := test - 1; idx < test_other; idx++ {
        fmt.Println(idx, a)
    }
}
