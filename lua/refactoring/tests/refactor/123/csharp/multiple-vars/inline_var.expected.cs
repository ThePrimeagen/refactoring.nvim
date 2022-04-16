namespace Test {
    class Order
    {
        int quantity;
        int itemPrice;
    }

    class Inline
    {
        double orderCalculation(Order order)
        {
            var i = 3.0f;

            return order.quantity * order.itemPrice -
                Math.Max(0, order.quantity - 500) * order.itemPrice * 0.05 +
                Math.Min(order.quantity * order.itemPrice * 0.1, 100.0);
        }
    }
}

