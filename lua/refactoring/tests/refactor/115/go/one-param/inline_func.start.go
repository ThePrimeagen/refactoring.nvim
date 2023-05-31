package main

import "fmt"

func extracted(a string) {
    fmt.Errorf(a)
}

func simple_function() {
    extracted("test")
    fmt.Println("test5")
    fn(errors.New("new error"))
    op()
}

func fn(err error) {
    extracted(err.Error())
}

func op() {
    extracted("a")
    extracted("a duplicated")
}
