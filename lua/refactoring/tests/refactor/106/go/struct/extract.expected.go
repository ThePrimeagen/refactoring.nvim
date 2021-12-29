package main

import "fmt"

type foobar struct {
   poggers int
}

func (f *foobar) foo(a INSERT_PARAM_TYPE, test INSERT_PARAM_TYPE, test_other INSERT_PARAM_TYPE) {
	for idx := test - 1; idx < test_other; idx++ {
		fmt.Println(f.poggers, idx, a)
	}
}

func (f *foobar) simple_function(a int) {
	var test int = 1
	test_other := 1
f.foo(a, test, test_other)

}
