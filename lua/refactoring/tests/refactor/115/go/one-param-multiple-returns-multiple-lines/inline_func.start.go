package main

import "fmt"

func extracted(a int) (int, error) {
    fmt.Println(a)
    fmt.Println(a * a)
    return a * 2, fmt.Errorf("an error")
}

func simple_function() {
    x, _ := extracted(1)
    fmt.Println("test1")
    fmt.Println(x)

    y, _ := extracted(x)
    fn := func() {
        z, _ := extracted(y + 2)
        fmt.Println(z)
    }
    fn()

    extracted(x)

    fmt.Println(extracted(x))
}
