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
    var basePrice = order.quantity * order.itemPrice;
    double blah = (basePrice) - 7;

    Console.WriteLine("%d %d", temp, blah);

    return basePrice
      - Math.max(0.0, order.quantity - 500) * order.itemPrice * 0.05
      + Math.min(basePrice * 0.1, 100.00);
  }
}
