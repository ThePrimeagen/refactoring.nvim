def orderCalculation(order, a, b)
  temp = a * b
  basePrice = order.quantity * order.itemPrice
  blah = (basePrice) - 7

  puts(temp, blah)

  basePrice - max(0, order.quantity - 500) * order.itemPrice * 0.05 + min(basePrice * 0.01, 100)
end
