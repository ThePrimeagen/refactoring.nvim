def orderCalculation(order):
    i = order.quantity * order.itemPrice
    print(i)
    return i - max(0, order.quantity - 500) * order.itemPrice * 0.05 + min(i * 0.1, 100)
