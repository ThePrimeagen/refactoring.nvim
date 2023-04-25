package main

import (
    "fmt"
)

type Person struct {
    firstName string
    lastName  string
}

func orderCalculation(person Person, start string, end string) string {
    space := " [space] "
    greeting := start + space + end

    fmt.Println(greeting)

    return start + person.firstName + space + person.lastName + end
}
