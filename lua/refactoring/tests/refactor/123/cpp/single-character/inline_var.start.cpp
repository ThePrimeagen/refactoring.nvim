#include <algorithm>

struct Order {
  int quantity;
  int itemPrice;
};

float orderCalculation(Order order) {
  float i = order.quantity * order.itemPrice;
  return i -
         std::max(0, order.quantity - 500) * order.itemPrice * 0.05 +
         std::min(i * 0.1, 100.0);
}
