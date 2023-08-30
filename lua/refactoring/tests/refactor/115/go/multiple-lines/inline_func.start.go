package main

import "fmt"

func extracted() {
    fmt.Errorf("test")
    fmt.Errorf("test")
    fmt.Errorf("test")
}

func simple_function() {
    extracted()
    fn = func() {
        extracted()
    }
}
