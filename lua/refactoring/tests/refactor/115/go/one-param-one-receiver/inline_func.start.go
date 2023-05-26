package main

import "fmt"

func extracted(param string) string {
	return "test"
}

func simple_function() {
	aa := extracted("a param")
	fmt.Println(aa)
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}
