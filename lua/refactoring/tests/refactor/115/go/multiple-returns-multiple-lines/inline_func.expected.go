package main

import "fmt"



func simple_function() error {
	a, b, err := 1, "a", fmt.Errorf("An error")
	if err == nil {
		return err
	}
	fmt.Println(a)
	fmt.Println(b)
	fmt.Println(1, "a", fmt.Errorf("An error"))
	var x int
	var y string
	var z error
	if x, y, z = 1, "a", fmt.Errorf("An error"); z == nil {
		fmt.Println(z)
	}
	fmt.Println(x + 10)
	fmt.Println(y + " world")
	fmt.Println(z)
	return nil
}
