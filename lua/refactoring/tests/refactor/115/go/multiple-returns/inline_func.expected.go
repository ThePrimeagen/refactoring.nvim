package main

import "fmt"




func simple_function() (bool, error) {
    b, err := true, fmt.Errorf("an error")
    if err != nil {
        panic(err)
    }
    fmt.Println(b)
    fn(true, fmt.Errorf("an error"))
    true, fmt.Errorf("an error")
    return true, fmt.Errorf("an error")
}

func fn(a bool, err error) {
    fmt.Println(a)
    panic(err)
}
