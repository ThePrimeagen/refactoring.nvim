package main

import "fmt"

func extracted(param string) {
	fmt.Println(param)
	fmt.Println(param + "" + param)
	fmt.Println("another line")
}

func simple_function() {
	extracted("a param")
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}

func simple_function2() {
	extracted("b param")
	fmt.Println("test6")
	fmt.Println("test7")
	fmt.Println("test8")
	fmt.Println("test9")
}
