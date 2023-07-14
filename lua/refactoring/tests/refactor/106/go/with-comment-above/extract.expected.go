package main

import "fmt"

func foo_bar(a int, test int, test_other INSERT_PARAM_TYPE) {
    for idx := test - 1; idx < test_other; idx++ {
        fmt.Println(idx, a)
    }
}

/* This is a multi line comment
comments are fun
I like comments as much as I like coconut oil */
func simple_function(a int) {
    var test int = 1
    test_other := 1
    foo_bar(a, test, test_other)
}
