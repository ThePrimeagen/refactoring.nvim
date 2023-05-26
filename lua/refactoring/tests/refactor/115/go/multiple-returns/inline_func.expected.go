package main

import "fmt"



func simple_function() {
val := map[string]int{
		"zapato": 1,
		"camion": 2,
	}
err := fmt.Errorf("an error")
	
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(val)
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}
