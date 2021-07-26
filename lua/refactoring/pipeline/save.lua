-- TODO: Likely unnecessary, but it could be nice if we needed to add any logic
-- to the saving process
local function save(refactor)
    vim.cmd([[ :w ]])
    return true, refactor
end
return save
