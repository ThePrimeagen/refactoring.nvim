package main

import "fmt"

func extracted() (int, string, error) {
	return 1, "a", fmt.Errorf("An error")
}

func simple_function() error {
	a, b, err := extracted()
	if err == nil {
		return err
	}
	fmt.Println(a)
	fmt.Println(b)
	fmt.Println(extracted())
	var x int
	var y string
	var z error
	if x, y, z = extracted(); z == nil {
		fmt.Println(z)
	}
	fmt.Println(x + 10)
	fmt.Println(y + " world")
	fmt.Println(z)
	return nil
}
