#include <algorithm>

struct Order {
  int quantity;
  int itemPrice;
};

float orderCalculation(Order order) {
  float basePrice = order.quantity * order.itemPrice;
  return basePrice -
         std::max(0, order.quantity - 500) * order.itemPrice * 0.05 +
         std::min(basePrice * 0.1, 100.0);
}
