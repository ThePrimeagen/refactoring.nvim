package main

import "math"

type Order struct {
    quantity  float64
    itemPrice float64
}

func orderCalculation(order Order) float64 {
    
    return order.quantity * order.itemPrice - math.Max(0, order.quantity-500)*order.itemPrice*0.05 + math.Min(order.quantity * order.itemPrice*0.1, 100.0)
}
