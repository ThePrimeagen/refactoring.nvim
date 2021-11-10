package main

import "fmt"

type foobar struct {
   poggers int
}

func (f *foobar) foo(a, test, test_other) {
    	for idx := test - 1; idx < test_other; idx++ {
		fmt.Println(f.poggers, idx, a)
	}
}

func (f *foobar) simple_function(a int) {
	var test int = 1
	test_other := 1

f.foo(a, test, test_other)

}
