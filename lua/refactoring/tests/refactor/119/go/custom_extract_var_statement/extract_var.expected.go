package main

import (
    "fmt"
    "math"
)

type Order struct {
    quantity  float64
    itemPrice float64
}

func orderCalculation(order Order, a int, b int) (total float64) {
    temp := a * b
    var basePrice float64 = order.quantity*order.itemPrice
    blah := (basePrice) - 7
    fmt.Println(blah, temp)
    return basePrice -
        math.Max(0, order.quantity-500)*order.itemPrice*0.05 +
        math.Min(basePrice*0.1, 100)
}
