namespace Test
{
    class Order
    {
        public double quantity { get; set; }
        public double itemPrice { get; set; }
    }

    class ExtractVar
    {
        public static double orderCalculation(Order order, int a, int b) {
            double temp = a * b;
            double blah = (order.quantity * order.itemPrice) - 7;

            Console.WriteLine("{0} {1}", temp, blah);

            return order.quantity * order.itemPrice -
                Math.Max(0.0, order.quantity - 500) * order.itemPrice * 0.05 +
                Math.Min(order.quantity * order.itemPrice * 0.1, 100.00);
      }
    }
}
