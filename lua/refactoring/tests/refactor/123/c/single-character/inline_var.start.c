#define max(a, b)                                                              \
  ({                                                                           \
    __typeof__(a) _a = (a);                                                    \
    __typeof__(b) _b = (b);                                                    \
    _a > _b ? _a : _b;                                                         \
  })

#define min(a, b)                                                              \
  ({                                                                           \
    __typeof__(a) _a = (a);                                                    \
    __typeof__(b) _b = (b);                                                    \
    _a < _b ? _a : _b;                                                         \
  })

struct Order {
  int quantity;
  int itemPrice;
};

float orderCalculation(struct Order order) {
  float i = order.quantity * order.itemPrice;
  return i - max(0, order.quantity - 500) * order.itemPrice * 0.05 +
         min(i * 0.1, 100.0);
}
