def order_calculation(order)
  i = order.quantity * order.itemPrice
  puts i
  i - max(0, order.quantity - 500) * order.itemPrice * 0.05 + min(i * 0.1, 100)
end
