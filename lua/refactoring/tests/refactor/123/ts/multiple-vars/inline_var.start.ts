type Order = {
    quantity: number;
    itemPrice: number;
}

// This the straight from the book (slight modifications)
function orderCalculation(order: Order) {
    const basePrice = order.quantity*order.itemPrice, i = 3;
    basePrice;
    return basePrice -
        Math.max(0, order.quantity - 500) * order.itemPrice * 0.05 +
        Math.min(basePrice * 0.1, 100);
}
