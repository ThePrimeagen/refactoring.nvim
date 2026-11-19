fn order_total(prices: &[i32], discount: i32) -> i32 {
    let mut total = 0;
    for price in prices {
        total += price;
    }
    prices.iter().for_each(|price| {
        println!("{}", price);
    });
    total - discount
}
