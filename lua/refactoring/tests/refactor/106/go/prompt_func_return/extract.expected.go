package main

import "fmt"

func foo(a int, test int) int {
    test_other := 1
    for idx := test - 1; idx < test_other; idx++ {
        fmt.Println(idx, a)
    }
    return test_other
}

func simple_function(a int) (int, int) {
    var test int = 1
    test_other := foo(a, test)


    return test, test_other
}
