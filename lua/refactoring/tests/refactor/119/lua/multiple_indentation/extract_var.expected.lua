local function greeter(names)
    for _, name in ipairs(names) do
        while name do
            if name ~= "world" then
                local hello = "hello %s"
                print(hello):format(name)
            end
            name = nil
        end
    end
end

greeter({
    "foo",
    "bar",
    "baz",
    "world",
})
