package main

import "fmt"

type Message struct{
    value int
}
type Response struct{}



func simple_function() {
    a := Message{value: 2}
    r := Response{}
    if a.value == 1 {
        // return r, nil
    }
    if a.value == 2 {
        if a.value > 2 {
            // return r, fmt.Errorf("Error")
        }
        // return Response{}, nil
    }
    if a.value == 3 {
        a.value = 5
    }
    x, err := r, nil
    if err != nil {
        panic(err)
    }
    fmt.Println(x)
}
