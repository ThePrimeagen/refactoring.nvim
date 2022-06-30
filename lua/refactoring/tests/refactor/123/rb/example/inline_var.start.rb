def order_calculation(order)
  basePrice = order.quantity * order.itemPrice
  puts basePrice
  basePrice - max(0, order.quantity - 500) * order.itemPrice * 0.05 + min(basePrice * 0.1, 100)
end
