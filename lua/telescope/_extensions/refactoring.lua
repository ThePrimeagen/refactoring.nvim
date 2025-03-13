local refactoring = require("refactoring")

local function refactor(prompt_bufnr)
    local content =
        require("telescope.actions.state").get_selected_entry(prompt_bufnr)
    require("telescope.actions").close(prompt_bufnr)
    vim.api.nvim_input(refactoring.refactor(content.value))
end

local function telescope_refactoring(opts)
    opts = opts or require("telescope.themes").get_cursor()

    local utils = require("refactoring.utils")
    if utils.is_visual_mode() then
        utils.exit_to_normal_mode()
    end

    require("telescope.pickers")
        .new(opts, {
            prompt_title = "refactors",
            finder = require("telescope.finders").new_table({
                results = refactoring.get_refactors(),
            }),
            sorter = require("telescope.config").values.generic_sorter(opts),
            attach_mappings = function(_, map)
                map("i", "<CR>", refactor)
                map("n", "<CR>", refactor)
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
