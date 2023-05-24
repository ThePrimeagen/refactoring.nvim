package main

import "fmt"

func extracted(used, unused1, unused2 string) {
	fmt.Errorf(used)
}

func simple_function() {
	extracted("test1", "test2", "test3")
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}
