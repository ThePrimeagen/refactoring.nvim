package main

import "fmt"

type foobar struct {
   poggers int
}

func (b *foobar) foo(a int, test int, test_other INSERT_PARAM_TYPE) {
    for idx := test - 1; idx < test_other; idx++ {
        fmt.Println(b.poggers, idx, a)
    }
}

func (b *foobar) simple_function(a int) {
    var test int = 1
    test_other := 1
    b.foo(a, test, test_other)
}
