package main

import "fmt"

type foobar struct {
   poggers int
}

func (b *foobar) simple_function(a int) {
    var test int = 1
    test_other := 1
    for idx := test - 1; idx < test_other; idx++ {
        fmt.Println(b.poggers, idx, a)
    }
}
