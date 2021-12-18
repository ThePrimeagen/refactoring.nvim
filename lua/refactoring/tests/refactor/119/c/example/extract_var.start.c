#include <stdio.h>

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
  double quantity;
  double itemPrice;
};

double orderCalculation(struct Order order, int a, int b) {
  float temp = a * b;
  float blah = (order.quantity * order.itemPrice) - 7;

  printf("%f %f", temp, blah);

  return order.quantity * order.itemPrice -
         max(0.0, order.quantity - 500) * order.itemPrice * 0.05 +
         min(order.quantity * order.itemPrice * 0.1, 100.00);
}
