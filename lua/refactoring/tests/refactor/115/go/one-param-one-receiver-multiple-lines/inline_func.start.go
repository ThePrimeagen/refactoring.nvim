package main

import "fmt"

func extracted(param string) string {
	fmt.Println(param)
	fmt.Println(param + "" + param)
	fmt.Println("another line")
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

func simple_function2() {
	bb := extracted("b param")
	fmt.Println(bb)
	fmt.Println("test6")
	fmt.Println("test7")
	fmt.Println("test8")
	fmt.Println("test9")
}
