package main

import "fmt"

/* This is a multi line comment
comments are fun
I like comments as much as I like coconut oil */
func simple_function(a int) {
    var test int = 1
    test_other := 1
    for idx := test - 1; idx < test_other; idx++ {
        fmt.Println(idx, a)
    }
}
