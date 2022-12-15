local a = 1
local b = 2
local order = {
    quantity = 3,
    itemPrice = 4,
}
local temp = a * b
local blah = (order.quantity * order.itemPrice) - 7

print(string.format("%d %d"), temp, blah)

return order.quantity * order.itemPrice
    - math.max(0, order.quantity - 500) * order.itemPrice * 0.05
    + math.min(order.quantity * order.itemPrice * 0.1, 100)
