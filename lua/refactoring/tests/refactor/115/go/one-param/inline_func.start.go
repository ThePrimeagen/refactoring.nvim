package main

import "fmt"

func extracted(a string) {
	fmt.Errorf(a)
}

func simple_function() {
	extracted("test")
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}
