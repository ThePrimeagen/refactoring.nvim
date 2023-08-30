package main

import "fmt"

type Message struct{
    value int
}
type Response struct{}

func extracted(a Message) (Response, error) {
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

    return r, nil
}

func simple_function() {
    x, err := extracted(Message{value: 2})
    if err != nil {
        panic(err)
    }
    fmt.Println(x)
}
