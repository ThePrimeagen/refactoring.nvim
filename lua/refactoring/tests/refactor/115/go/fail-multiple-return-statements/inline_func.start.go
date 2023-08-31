package main

import "fmt"

func extracted() (bool, error) {
    res := false
    if !res {
    	return false, fmt.Errorf("an error")
    }
    return true, fmt.Errorf("an error")
}


func simple_function() (bool, error) {
    b, err := extracted()
    if err != nil {
        panic(err)
    }
    fmt.Println(b)
    fn(extracted())
    extracted()
    return extracted()
}

func fn(a bool, err error) {
    fmt.Println(a)
    panic(err)
}
