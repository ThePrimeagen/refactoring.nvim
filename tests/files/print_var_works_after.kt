fun orderTotal(prices: List<Int>, discount: Int): Int {
    var total = 0
    for (price in prices) {
        total += price
        // __PRINT_VAR_START
        println($$"""┆orderTotal#for┆ ╎total╎ ┊1┊: $${total}""")// __PRINT_VAR_END
    }
    prices.forEach { price ->
        println(price)
    }
    return total - discount
}
