class Order
{
  int quantity;
  int itemPrice;
}

class Inline
{
  double orderCalculation(Order order)
  {
    
    return order.quantity * order.itemPrice - Math.max(0, order.quantity - 500) * order.itemPrice * 0.05 + Math.min(order.quantity * order.itemPrice * 0.1, 100.0);
  }
}
