package main

import "fmt"



func simple_function() string {
    fmt.Println("test1")
    fmt.Println("test2")
    fmt.Println("test3")
    if 1 == 1 {
        return "true"
    }
    fmt.Println("test1")
    fmt.Println("test2")
    fmt.Println("test3")
    if !1 == 1 {
        return "false"
    }
    fmt.Println("test1")
    fmt.Println("test2")
    fmt.Println("test3")
    fmt.Println("test1")
    fmt.Println("test2")
    fmt.Println("test3")
    if 1 == !1 {
        return "missmatch"
    }
    fn()
    fmt.Println("test1")
    fmt.Println("test2")
    fmt.Println("test3")
    with_param(1)
    fmt.Println("test1")
    fmt.Println("test2")
    fmt.Println("test3")
    fmt.Println("test1")
    fmt.Println("test2")
    fmt.Println("test3")
    aa := operation(1, 1)
    fmt.Println(aa)
    fmt.Println("test1")
    fmt.Println("test2")
    fmt.Println("test3")
    fmt.Println("test1")
    fmt.Println("test2")
    fmt.Println("test3")
    bb := operation(1 + 1, 2)
    fmt.Println(bb)
    retrun "false"
}

func fn() int {
    fmt.Println("test1")
    fmt.Println("test2")
    fmt.Println("test3")
    return 1
}

func with_param(b int) {
    fmt.Println(b)
}

func operation(a, b int) int {
    return a + b
}
