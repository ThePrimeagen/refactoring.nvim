def order_calculation(order)
  
  puts order.quantity * order.itemPrice
  order.quantity * order.itemPrice - max(0, order.quantity - 500) * order.itemPrice * 0.05 + min(order.quantity * order.itemPrice * 0.1, 100)
end
