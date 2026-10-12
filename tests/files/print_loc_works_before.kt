fun orderTotal(prices: List<Int>): Int {
    var total = 0
    for (price in prices) {
        if (price > 0) {
            total += price
        }
    }
    return total
}
