package main

import "fmt"



func simple_function() {
    a := 1
    x, _ := a * 2, fmt.Errorf("an error")
    fmt.Println("test1")
    fmt.Println(x)

    a := x
    y, _ := a * 2, fmt.Errorf("an error")
    fn := func() {
        a := y + 2
        z, _ := a * 2, fmt.Errorf("an error")
        fmt.Println(z)
    }
    fn()

    a := x
    a * 2, fmt.Errorf("an error")

    a := x
    fmt.Println(a * 2, fmt.Errorf("an error"))
}
