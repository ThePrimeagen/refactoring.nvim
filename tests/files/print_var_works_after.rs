fn order_total(prices: &[i32], discount: i32) -> i32 {
    let mut total = 0;
    for price in prices {
        total += price;
        // __PRINT_VAR_START
        println!("┆order_total#for┆ ╎total╎ ┊1┊: {:?}", total);// __PRINT_VAR_END
    }
    prices.iter().for_each(|price| {
        println!("{}", price);
    });
    total - discount
}
