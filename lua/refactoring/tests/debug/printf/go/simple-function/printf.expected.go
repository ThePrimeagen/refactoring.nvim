package main

import "fmt"

func simple_function(a int) {
    var test int = 1
    test_other := 1
    for idx := test - 1; idx < test_other; idx++ {
        fmt.Println(idx, a)
        // __AUTO_GENERATED_PRINTF_START__
        fmt.Println("simple_function 1") // __AUTO_GENERATED_PRINTF_END__
    }
}
