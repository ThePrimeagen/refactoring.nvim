package org.example

fun main() {

    println("foo")

    while (true) {
        println("foo")
        break
    }

    do {
        println("foo")
    } while (false)

    if (true) {
        println("foo")
    } else {
        println("foo")
    }

    for (i in 0 until 5) {
        println("foo")
    }

}
