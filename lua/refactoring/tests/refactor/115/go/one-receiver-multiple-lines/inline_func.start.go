package main

import "fmt"

func extracted() string {
	fmt.Println("xyz1")
	fmt.Println("xyz2")
	fmt.Println("xyz3")
	fmt.Println("xyz4")
	return "zapato"
}

func simple_function() {
	aa := extracted()
	fmt.Println(aa)
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}
