fn receipt(amount: i32, tip: i32) -> String {
    let total = (amount + tip) * 2;
    // __PRINT_EXP_START
    println!("┆receipt┆ ╎amount + tip╎ ┊1┊: {:?}", amount + tip);// __PRINT_EXP_END
    // __PRINT_EXP_START
    println!("┆receipt┆ ╎format!(\"Total: {{}}\", total)╎ ┊1┊: {:?}", format!("Total: {}", total));// __PRINT_EXP_END
    format!("Total: {}", total)
}
