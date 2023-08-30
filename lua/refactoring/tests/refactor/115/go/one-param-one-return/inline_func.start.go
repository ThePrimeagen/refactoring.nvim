package main

import "fmt"

func extracted(a int) int {
    return a * 2
}

func simple_function() {
    x := extracted(1)
    fmt.Println("test1")
    fmt.Println(x)

    y := extracted(x)
    fn := func() {
        z := extracted(y + 2)
        fmt.Println(z)
    }
    fn()

    extracted(x)
}
