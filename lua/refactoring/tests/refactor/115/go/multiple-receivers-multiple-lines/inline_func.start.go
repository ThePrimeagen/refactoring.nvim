package main

import "fmt"

func extracted() (string, string) {
	fmt.Println("xyz1")
	fmt.Println("xyz2")
	fmt.Println("xyz3")
	fmt.Println("xyz4")
	return "zapato", "camion"
}

func simple_function() {
	aa, bb := extracted()
	fmt.Println(aa)
	fmt.Println(bb)
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}
