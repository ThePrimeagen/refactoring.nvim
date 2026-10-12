fun orderTotal(prices: List<Int>, discount: Int): Int {
    var total = 0
    for (price in prices) {
        total += price
    }
    prices.forEach { price ->
        println(price)
    }
    return total - discount
}
