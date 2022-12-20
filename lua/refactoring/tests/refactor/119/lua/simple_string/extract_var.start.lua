-- stylua: ignore start

local function orderCalculation(person, start, _end)
    local greeting = start .. " [space] " .. _end

    print(greeting)

    return start .. person.firstName .. " [space] " .. person.lastName .. _end
end
