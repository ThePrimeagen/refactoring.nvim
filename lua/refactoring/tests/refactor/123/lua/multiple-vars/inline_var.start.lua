-- stylua: ignore start

local function orderCalculation(order)
    local basePrice, i = order.quantity * order.itemPrice, 3
    return basePrice
        - math.max(0, order.quantity - 500) * order.itemPrice * 0.05
        + math.min(basePrice * 0.1, 100)
end
