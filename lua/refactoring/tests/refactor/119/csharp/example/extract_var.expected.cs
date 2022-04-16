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
            var basePrice = order.quantity * order.itemPrice;
            double blah = (basePrice) - 7;

            Console.WriteLine("{0} {1}", temp, blah);

            return basePrice -
                Math.Max(0.0, order.quantity - 500) * order.itemPrice * 0.05 +
                Math.Min(basePrice * 0.1, 100.00);
        }
    }
}

