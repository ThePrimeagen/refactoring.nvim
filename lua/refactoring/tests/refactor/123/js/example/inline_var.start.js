// This the straight from the book (slight modifications)
function orderCalculation(order) {
    const basePrice = order.quantity * order.itemPrice;
    basePrice;
    return (
        basePrice -
        Math.max(0, order.quantity - 500) * order.itemPrice * 0.05 +
        Math.min(basePrice * 0.1, 100)
    );
}
