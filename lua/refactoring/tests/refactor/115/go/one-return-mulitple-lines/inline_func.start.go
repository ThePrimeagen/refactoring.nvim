package main

import "fmt"

func extracted() int {
    fmt.Println("test1")
    fmt.Println("test2")
    fmt.Println("test3")
    return 1
}

func simple_function() string {
    if extracted() == 1 {
        return "true"
    }
    if !extracted() == 1 {
        return "false"
    }
    if extracted() == !extracted() {
        return "missmatch"
    }
    fn()
    with_param(extracted())
    aa := operation(extracted(), extracted())
    fmt.Println(aa)
    bb := operation(extracted() + extracted(), 2)
    fmt.Println(bb)
    retrun "false"
}

func fn() int {
    return extracted()
}

func with_param(b int) {
    fmt.Println(b)
}

func operation(a, b int) int {
    return a + b
}
