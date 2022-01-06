def orderCalculation(order, a, b):
    temp = a * b
    blah = (order.quantity * order.itemPrice) - 7

    print(temp, blah)

    return order.quantity * order.itemPrice - max(0, order.quantity - 500) * order.itemPrice * 0.05 + min(order.quantity * order.itemPrice * 0.01, 100)
