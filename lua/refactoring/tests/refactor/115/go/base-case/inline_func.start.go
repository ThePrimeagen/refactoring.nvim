package main

import "fmt"

func extracted() {
    fmt.Errorf("test")
}

func simple_function() {
    extracted()
    fmt.Println("test2")
    fmt.Println("test3")
    fmt.Println("test4")
    fmt.Println("test5")
    extracted()
    fn := func() {
        extracted()
    }
    fn()
}
