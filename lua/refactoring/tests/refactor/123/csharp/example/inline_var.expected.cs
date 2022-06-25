namespace Test
{
    class Order
    {
        public int quantity { get; set; }
        public int itemPrice { get; set; }
    }

    class Inline
    {
        double orderCalculation(Order order)
        {
            return order.quantity * order.itemPrice -
                Math.Max(0, order.quantity - 500) * order.itemPrice * 0.05 +
                Math.Min(order.quantity * order.itemPrice * 0.1, 100.0);
        }
    }
}

