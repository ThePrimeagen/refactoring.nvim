-- stylua: ignore start

local function orderCalculation(order)
    local i = order.quantity * order.itemPrice
    return i
        - math.max(0, order.quantity - 500) * order.itemPrice * 0.05
        + math.min(i * 0.1, 100)
end
