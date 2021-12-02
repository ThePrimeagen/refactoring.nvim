package main

import "fmt"

type foobar struct {
   poggers int
}

func (b *foobar) foo(a, test, test_other) {
	for idx := test - 1; idx < test_other; idx++ {
		fmt.Println(b.poggers, idx, a)
	}
}

func (b *foobar) simple_function(a int) {
	var test int = 1
	test_other := 1
b.foo(a, test, test_other)

}
