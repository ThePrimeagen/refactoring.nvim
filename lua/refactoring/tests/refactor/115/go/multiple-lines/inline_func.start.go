package main

import "fmt"

func extracted() string {
	fmt.Println("abc1")
	fmt.Println("abc2")
	fmt.Println("abc3")
	fmt.Println("abc4")
}

func simple_function() {
	extracted()
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}
