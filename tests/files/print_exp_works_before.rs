fn receipt(amount: i32, tip: i32) -> String {
    let total = (amount + tip) * 2;
    format!("Total: {}", total)
}
