package main

import "fmt"

type foobar struct {
   poggers int
}

func (f *foobar) simple_function(a int) (int, int) {
    var test int = 1
    test_other := 1
    for idx := test - 1; idx < test_other; idx++ {
        fmt.Println(f.poggers, idx, a)
    }

    return test, test_other
}
