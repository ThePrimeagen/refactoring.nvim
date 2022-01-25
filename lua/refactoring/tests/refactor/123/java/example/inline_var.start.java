class Order {
  int quantity;
  int itemPrice;
}

class Inline {
  double orderCalculation(Order order) {
    float basePrice = order.quantity * order.itemPrice;
    return basePrice -
        Math.max(0, order.quantity - 500) * order.itemPrice * 0.05 +
        Math.min(basePrice * 0.1, 100.0);
  }
}
