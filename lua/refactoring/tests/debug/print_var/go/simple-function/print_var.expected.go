package main

import "fmt"

func simple_function(a int) {
	var test int = 1
	test_other := 1
fmt.Println(fmt.Sprintf("simple_function test_other: %v", test_other))
	for idx := test - 1; idx < test_other; idx++ {
		fmt.Println(idx, a)
	}
}
