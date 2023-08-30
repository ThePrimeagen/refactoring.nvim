package main

import "fmt"



func simple_function() {
    a := 1
    x := a * 2
    fmt.Println("test1")
    fmt.Println(x)

    a := x
    y := a * 2
    fn := func() {
        a := y + 2
        z := a * 2
        fmt.Println(z)
    }
    fn()

    a := x
    a * 2
}
