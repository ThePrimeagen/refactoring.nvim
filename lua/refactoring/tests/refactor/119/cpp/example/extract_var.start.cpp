#include <algorithm>
#include <iostream>

struct Order {
  double quantity;
  double itemPrice;
};

double orderCalculation(Order order, int a, int b) {
  float temp = a * b;
  float blah = (order.quantity * order.itemPrice) - 7;

  std::cout << temp << " " << blah << std::endl;

  return order.quantity * order.itemPrice -
         std::max(0.0, order.quantity - 500) * order.itemPrice * 0.05 +
         std::min(order.quantity * order.itemPrice * 0.1, 100.00);
}
