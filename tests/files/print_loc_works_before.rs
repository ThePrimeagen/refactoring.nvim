fn order_total(prices: &[i32]) -> i32 {
    let mut total = 0;
    for price in prices {
        if *price > 0 {
            total += price;
        }
    }
    total
}
