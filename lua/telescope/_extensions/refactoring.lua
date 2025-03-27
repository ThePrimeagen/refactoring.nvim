local refactoring = require("refactoring")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")

local function refactor(prompt_bufnr)
    actions.close(prompt_bufnr)
    local content = action_state.get_selected_entry()

    -- NOTE: telescope leaves Neovim in insert mode after exiting and even trying to change into normal mode doesn't work
    -- Is this a bug with telescope? Or with Neovim input buffers?
    vim.schedule(function()
        local keys = refactoring.refactor(content.value)
        if keys == "g@" then
            keys = "gvg@"
        end
        vim.cmd.normal(keys)
    end)
end

local function telescope_refactoring(opts)
    opts = opts or require("telescope.themes").get_cursor()

    require("telescope.pickers")
        .new(opts, {
            prompt_title = "refactors",
            finder = require("telescope.finders").new_table({
                results = refactoring.get_refactors(),
            }),
            sorter = require("telescope.config").values.generic_sorter(opts),
            attach_mappings = function()
                actions.select_default:replace(refactor)
                return true
            end,
        })
        :find()
end

return require("telescope").register_extension({
    exports = {
        refactors = telescope_refactoring,
    },
})
