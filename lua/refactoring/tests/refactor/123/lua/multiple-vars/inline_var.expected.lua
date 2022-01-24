-- stylua: ignore start

local function orderCalculation(order)
    local i = 3

    return order.quantity * order.itemPrice
        - math.max(0, order.quantity - 500) * order.itemPrice * 0.05
        + math.min(order.quantity * order.itemPrice * 0.1, 100)
end
