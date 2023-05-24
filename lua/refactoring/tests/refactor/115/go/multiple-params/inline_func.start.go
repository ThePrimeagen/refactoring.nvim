package main

import "fmt"

func extracted(a, b, c string) {
	fmt.Errorf(a, b, c)
}

func simple_function() {
	extracted("test1", "test2", "test3")
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}
