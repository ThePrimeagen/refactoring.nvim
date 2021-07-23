local function asdf(offset)
    local another_thing = {}
    for i = 1, 10 do
        table.insert(another_thing, i + offset)
    end
    return another_thing
end
local function y(offset)
    print("yo")

    local another_thing = asdf(offset)
    print("yo", another_thing)
end

y(10)
