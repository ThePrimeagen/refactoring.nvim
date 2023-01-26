package main

import "fmt"

func simple_function(a int) {
    var test int = 1
    test_other := 1
    for idx := test - 1; idx < test_other; idx++ {
        fmt.Println(idx, a)
    }
}
