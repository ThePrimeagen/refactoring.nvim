package main

import "fmt"



func simple_function() {
    fmt.Errorf("test")
    
    fmt.Println("test2")
    fmt.Println("test3")
    fmt.Println("test4")
    fmt.Println("test5")
    fmt.Errorf("test")
    
    fn := func() {
        fmt.Errorf("test")
        
    }
    fn()
}
