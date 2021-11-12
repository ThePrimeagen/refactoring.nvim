package main

import "fmt"

func foo_bar(a, test, test_other) {
    	for idx := test - 1; idx < test_other; idx++ {
		fmt.Println(idx, a)
	}
}

func simple_function(a int) {
	var test int = 1
	test_other := 1
foo_bar(a, test, test_other)

}
