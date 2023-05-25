package main

import "fmt"

func extracted() string {
	return "test"
}

func simple_function() {
	aa := extracted()
	fmt.Println(aa)
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}
