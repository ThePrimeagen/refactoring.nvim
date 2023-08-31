package main

import "fmt"



func simple_function() {
    a := "test"
    fmt.Errorf(a)
    fmt.Println("test5")
    fn(errors.New("new error"))
    op()
}

func fn(err error) {
    a := err.Error()
    fmt.Errorf(a)
}

func op() {
    a := "a"
    fmt.Errorf(a)
    a := "a duplicated"
    fmt.Errorf(a)
}
