// This the straight from the book (slight modifications)
function orderCalculation(order) {
    const i = 3;

    order.quantity * order.itemPrice;
    return (
        order.quantity * order.itemPrice -
        Math.max(0, order.quantity - 500) * order.itemPrice * 0.05 +
        Math.min(order.quantity * order.itemPrice * 0.1, 100)
    );
}
