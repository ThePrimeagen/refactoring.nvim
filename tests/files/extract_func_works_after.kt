package org.example

class Calculator {
    private fun bar(subtotal: P, taxRate: Double): P {
        val tax = subtotal * taxRate
        println("Subtotal: $subtotal")

        return tax
    }

    fun total(prices: List<Int>, taxRate: Double): Double {
        val subtotal = prices.sum()

        val tax = bar(subtotal, taxRate)

        val result = subtotal + tax
        return result
    }
}
