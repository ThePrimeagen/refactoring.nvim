def orderCalculation(order):
    basePrice, i = order.quantity * order.itemPrice, 3
    print(basePrice)
    return basePrice - max(0, order.quantity - 500) * order.itemPrice * 0.05 + min(basePrice * 0.1, 100)
