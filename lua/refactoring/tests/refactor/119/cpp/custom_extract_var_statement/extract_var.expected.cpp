#include <algorithm>
#include <iostream>

struct Order {
  double quantity;
  double itemPrice;
};

double orderCalculation(Order order, int a, int b) {
  float temp = a * b;
  const auto basePrice = order.quantity * order.itemPrice;
  float blah = (basePrice) - 7;

  std::cout << temp << " " << blah << std::endl;

  return basePrice -
         std::max(0.0, order.quantity - 500) * order.itemPrice * 0.05 +
         std::min(basePrice * 0.1, 100.00);
}
