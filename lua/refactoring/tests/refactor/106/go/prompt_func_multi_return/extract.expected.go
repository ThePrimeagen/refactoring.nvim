package main

import "fmt"

func foo(a int) (int, int) {
    var test int = 1
    test_other := 1
    for idx := test - 1; idx < test_other; idx++ {
        fmt.Println(idx, a)
    }
    return test, test_other
}

func simple_function(a int) (int, int) {
    test, test_other := foo(a)


    return test, test_other
}
