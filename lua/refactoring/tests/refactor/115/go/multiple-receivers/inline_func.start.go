package main

import "fmt"

func extracted() (map[string]int, error) {
	return map[string]int{
		"zapato": 1,
		"camion": 2,
	}, fmt.Errorf("an error")
}

func simple_function() {
	val, err := extracted()
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(val)
	fmt.Println("test2")
	fmt.Println("test3")
	fmt.Println("test4")
	fmt.Println("test5")
}
