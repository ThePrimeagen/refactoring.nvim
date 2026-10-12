fun receipt(amount: Int, tip: Int): String {
    val summary = "Total: $" + (amount + tip)
    // __PRINT_EXP_START
    println($$"""┆receipt┆ ╎"Total: $" + (amount + tip)╎ ┊1┊: $${"Total: $" + (amount + tip)}""")// __PRINT_EXP_END
    // __PRINT_EXP_START
    println($$"""┆receipt┆ ╎amount + tip╎ ┊1┊: $${amount + tip}""")// __PRINT_EXP_END
    return summary
}
