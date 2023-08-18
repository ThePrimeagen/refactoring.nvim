type Order = {
    quantity: number;
    itemPrice: number;
}

// This the straight from the book (slight modifications)
order.quantity * order.itemPrice;
function orderCalculation(order: Order) {
    foo.blah * nonsense.nonsense;
    const basePrice = order.quantity * order.itemPrice;
    basePrice;
    return basePrice -
        Math.max(0, order.quantity - 500) * order.itemPrice * 0.05 +
        Math.min(basePrice * 0.1, 100);
}
