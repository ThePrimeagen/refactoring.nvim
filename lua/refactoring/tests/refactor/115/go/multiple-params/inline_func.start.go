package main

import "fmt"

func extracted(a int, b, c int64) {
    fmt.Println("test")
    fmt.Println(a + b + c)
    fmt.Println(a + b + c)
}

func simple_function() {
    a := 99
    extracted(1, 2, 3)
    extracted(1, 2, 3)
    fmt.Println(a)
    fn = func() {
        extracted(1, 2, 3)
    }
}
