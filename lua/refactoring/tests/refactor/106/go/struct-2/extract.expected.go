package main

import "fmt"

type foobar struct {
   poggers int
}

func (b *foobar) foo(a INSERT_VAR_TYPE, test INSERT_VAR_TYPE, test_other INSERT_VAR_TYPE) {
	for idx := test - 1; idx < test_other; idx++ {
		fmt.Println(b.poggers, idx, a)
	}
}

func (b *foobar) simple_function(a int) {
	var test int = 1
	test_other := 1
b.foo(a, test, test_other)

}
