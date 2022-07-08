local Pipeline = require("refactoring.pipeline")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local Region = require("refactoring.region")
local lsp_utils = require("refactoring.lsp_utils")
local post_refactor = require("refactoring.tasks.post_refactor")

local function cleanup(bufnr, config)
    return Pipeline:from_task(refactor_setup(bufnr, config))
        :add_task(function(refactor)
            local opts = refactor.config:get()
            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
            refactor.text_edits = {}

            -- set default cleanup behavior
            if opts.printf == nil then
                opts.printf = true
            end

            if opts.print_var == nil then
                opts.print_var = true
            end

            for row_num, line in ipairs(lines) do
                local region
                if row_num ~= 1 then
                    region = Region:from_values(
                        bufnr,
                        row_num - 1,
                        100000,
                        row_num,
                        100000
                    )
                else
                    print(
                        "NOTE! Can't delete first line of file, leaving blank"
                    )
                    region =
                        Region:from_values(bufnr, row_num, 1, row_num, 100000)
                end

                if opts.printf then
                    if
                        string.find(line, "__AUTO_GENERATED_PRINTF__") ~= nil
                    then
                        table.insert(
                            refactor.text_edits,
                            lsp_utils.delete_text(region)
                        )
                    end
                end

                if opts.print_var then
                    if
                        string.find(line, "__AUTO_GENERATED_PRINT_VAR__") ~= nil
                    then
                        table.insert(
                            refactor.text_edits,
                            lsp_utils.delete_text(region)
                        )
                    end
                end
            end

            return true, refactor
        end)
        :after(post_refactor.post_refactor)
        :run()
end

return cleanup
