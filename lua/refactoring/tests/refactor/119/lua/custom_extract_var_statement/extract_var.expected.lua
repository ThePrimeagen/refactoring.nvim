-- stylua: ignore start

local function orderCalculation(order, a, b)
    local temp = a * b
    local basePrice = order.quantity * order.itemPrice -- poggers!
    local blah = (basePrice) - 7

    print(string.format("%d %d"), temp, blah)

    return basePrice
        - math.max(0, order.quantity - 500) * order.itemPrice * 0.05
        + math.min(basePrice * 0.1, 100)
end
