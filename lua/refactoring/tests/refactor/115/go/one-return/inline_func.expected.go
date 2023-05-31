package main

import "fmt"



func simple_function() string {
	fmt.Println("test" + "A")
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
	fmt.Println("test" + "A" + "test" + "A")
	fn := func() {
		fmt.Println("test" + "A" + "test" + "A" + "test" + "A")
	}
	fn()
	zapato("test" + "A")
	ee := "test" + "A"
	return "test" + "A"
}

func zapato(aa string) {
	fmt.Println(aa)
}
