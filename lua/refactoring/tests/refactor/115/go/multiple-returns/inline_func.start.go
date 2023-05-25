package main

import "fmt"

func extracted() (string, string, string, string) {
	return "test", "an error", "third", "fourth"
}

func simple_function() {
	aa, err, bb, cc := extracted()
	fmt.Println(aa)
	fmt.Println(err)
	fmt.Println(bb)
	fmt.Println(cc)
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}
