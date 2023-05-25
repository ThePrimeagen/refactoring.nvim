package main

import "fmt"

func extracted() (string, string) {
	return "test", "an error"
}

func simple_function() {
	aa, err := extracted()
	fmt.Println(aa)
	fmt.Println(err)
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}
