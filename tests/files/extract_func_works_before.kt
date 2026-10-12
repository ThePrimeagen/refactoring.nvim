package org.example

class Calculator {
    fun total(prices: List<Int>, taxRate: Double): Double {
        val subtotal = prices.sum()

        val tax = subtotal * taxRate
        println("Subtotal: $subtotal")

        val result = subtotal + tax
        return result
    }
}
