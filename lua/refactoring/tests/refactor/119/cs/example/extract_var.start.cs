class Order
{
  double quantity;
  double itemPrice;
}

class ExtractVar
{
  public static double orderCalculation(Order order, int a, int b)
  {
    double temp = a * b;
    double blah = (order.quantity * order.itemPrice) - 7;

    Console.WriteLine("%d %d", temp, blah);

    return order.quantity * order.itemPrice
      - Math.max(0.0, order.quantity - 500) * order.itemPrice * 0.05
      + Math.min(order.quantity * order.itemPrice * 0.1, 100.00);
  }
}
