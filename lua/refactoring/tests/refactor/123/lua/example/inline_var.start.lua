-- stylua: ignore start

local function orderCalculation(order)
    local basePrice = order.quantity * order.itemPrice
    return basePrice
        - math.max(0, order.quantity - 500) * order.itemPrice * 0.05
        + math.min(basePrice * 0.1, 100)
end
