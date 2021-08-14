local Query = require("refactoring.query")

local function refactor_setup(bufnr, options)
    bufnr = bufnr or vim.fn.bufnr()

    return function()
        local filetype = vim.bo[bufnr].filetype
        local root = Query.get_root(bufnr, filetype)
        local refactor = {
            code = options.get_code_generation_for(filetype),
            filetype = filetype,
            bufnr = bufnr,
            query = Query:new(
                bufnr,
                filetype,
                vim.treesitter.get_query(filetype, "refactoring")
            ),
            locals = Query:new(
                bufnr,
                filetype,
                vim.treesitter.get_query(filetype, "locals")
            ),
            root = root,
            options = options,
            buffers = { bufnr },
        }

        return true, refactor
    end
end

return refactor_setup
