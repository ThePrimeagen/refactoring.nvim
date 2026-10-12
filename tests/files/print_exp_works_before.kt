fun receipt(amount: Int, tip: Int): String {
    val summary = "Total: $" + (amount + tip)
    return summary
}
