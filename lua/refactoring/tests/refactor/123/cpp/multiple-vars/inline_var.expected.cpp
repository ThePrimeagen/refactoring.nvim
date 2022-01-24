#include <algorithm>

struct Order {
  int quantity;
  int itemPrice;
};

float orderCalculation(Order order) {
  auto i = 3;

  return order.quantity * order.itemPrice -
         std::max(0, order.quantity - 500) * order.itemPrice * 0.05 +
         std::min(order.quantity * order.itemPrice * 0.1, 100.0);
}
