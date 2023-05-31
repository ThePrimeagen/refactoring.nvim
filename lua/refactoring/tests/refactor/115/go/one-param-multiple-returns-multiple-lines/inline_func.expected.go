package main

import "fmt"



func simple_function() {
    a := 1
    fmt.Println(a)
    fmt.Println(a * a)
    x, _ := a * 2, fmt.Errorf("an error")
    fmt.Println("test1")
    fmt.Println(x)

    a := x
    fmt.Println(a)
    fmt.Println(a * a)
    y, _ := a * 2, fmt.Errorf("an error")
    fn := func() {
        a := y + 2
        fmt.Println(a)
        fmt.Println(a * a)
        z, _ := a * 2, fmt.Errorf("an error")
        fmt.Println(z)
    }
    fn()

    a := x
    fmt.Println(a)
    fmt.Println(a * a)
    a * 2, fmt.Errorf("an error")

    a := x
    fmt.Println(a)
    fmt.Println(a * a)
    fmt.Println(a * 2, fmt.Errorf("an error"))
}
