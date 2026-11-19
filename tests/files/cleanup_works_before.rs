fn cleaned_up(count: i32) -> i32 {
    // __PRINT_LOC_START
    println!("┆cleaned_up┆ ┊1┊"); // __PRINT_LOC_END
    let doubled = count * 2;
    // __PRINT_VAR_START
    println!("┆cleaned_up┆ ╎doubled╎ ┊1┊: {:?}", doubled); // __PRINT_VAR_END
    // __PRINT_EXP_START
    println!("┆cleaned_up┆ ╎count + 1╎ ┊1┊: {:?}", count + 1); // __PRINT_EXP_END
    doubled
}
