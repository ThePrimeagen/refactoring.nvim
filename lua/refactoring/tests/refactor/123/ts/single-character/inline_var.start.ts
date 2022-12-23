type Order = {
    quantity: number;
    itemPrice: number;
}

// This the straight from the book (slight modifications)
function orderCalculation(order: Order) {
    const i = order.quantity*order.itemPrice;
    i;
    return i -
        Math.max(0, order.quantity - 500) * order.itemPrice * 0.05 +
        Math.min(i * 0.1, 100);
}
