package main

import "fmt"

func extracted() {
	fmt.Errorf("test")
}

func simple_function() {
	extracted()
	extracted()
	fmt.Println("test2")
	fmt.Println("test3")
	extracted()
	fmt.Println("test4")
	fmt.Println("test5")
	extracted()
}

func simple_function_two() func() {
	extracted()
	return func() {
		extracted()
	}
}
