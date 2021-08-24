local M = {}

M.make_whitespace = function(count)
    local temp = {}
    for i = 1, count do
        temp[i] = " "
    end
    return table.concat(temp)
end

M.get_whitespace = function(str)
    local start_col = 0
    for i = 1, #str do
        if str:sub(i, i) ~= " " then
            -- Have to minus 1 because it starts at 1... because lua
            start_col = i - 1
            break
        end
    end
    return start_col
end

return M
