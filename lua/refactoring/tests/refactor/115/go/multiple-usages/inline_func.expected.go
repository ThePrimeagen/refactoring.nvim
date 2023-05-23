package main

import "fmt"



func simple_function() {
	fmt.Errorf("test")
	fmt.Errorf("test")
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Errorf("test")
	fmt.Println("test4")
	fmt.Println("test5")
	fmt.Errorf("test")
}

func simple_function_two() func() {
	fmt.Errorf("test")
	return func() {
		fmt.Errorf("test")
	}
}
