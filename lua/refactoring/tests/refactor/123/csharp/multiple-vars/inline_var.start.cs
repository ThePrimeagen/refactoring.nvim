namespace Test
{
    class Order
    {
        int quantity { get; set; }
        int itemPrice { get; set; }
    }

    class Inline
    {
        double orderCalculation(Order order)
        {
            float basePrice = order.quantity * order.itemPrice, i = 3.0f;
            return basePrice -
                Math.Max(0, order.quantity - 500) * order.itemPrice * 0.05 +
                Math.Min(basePrice * 0.1, 100.0);
        }
    }
}

