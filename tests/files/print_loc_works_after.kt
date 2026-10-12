fun orderTotal(prices: List<Int>): Int {
    var total = 0
    for (price in prices) {
        if (price > 0) {
            total += price
            // __PRINT_LOC_START
            println($$"""┆orderTotal#for#if┆ ┊1┊""")// __PRINT_LOC_END
        }
    }
    return total
}
