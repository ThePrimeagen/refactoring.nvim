package main

import "fmt"

type foobar struct {
   poggers int
}

func (f *foobar) foo(a int, test int) INPUT_RETURN_TYPE {
    test_other := 1
    for idx := test - 1; idx < test_other; idx++ {
        fmt.Println(f.poggers, idx, a)
    }
    return test_other
}

func (f *foobar) simple_function(a int) (int, int) {
    var test int = 1
    test_other := f.foo(a, test)


    return test, test_other
}
