package main

import "fmt"

func extracted() string {
	return "test" + "A"
}

func simple_function() string {
	fmt.Println(extracted())
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
	fmt.Println(extracted() + extracted())
	fn := func() {
		fmt.Println(extracted() + extracted() + extracted())
	}
	fn()
	zapato(extracted())
	ee := extracted()
	return extracted()
}

func zapato(aa string) {
	fmt.Println(aa)
}
