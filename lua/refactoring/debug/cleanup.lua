local Pipeline = require("refactoring.pipeline")
local tasks = require("refactoring.tasks")
local Region = require("refactoring.region")
local text_edits_utils = require("refactoring.text_edits_utils")
local notify = require("refactoring.notify")

---@param bufnr integer
---@param config refactor.Config
local function cleanup(bufnr, config)
    local seed = tasks.refactor_seed(bufnr, nil, config)
    Pipeline
        :from_task(
            ---@param refactor refactor.Refactor
            function(refactor)
                local opts = refactor.config:get()
                local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
                refactor.text_edits = {}

                if opts.printf == nil then
                    opts.printf = true
                end

                if opts.print_var == nil then
                    opts.print_var = true
                end

                for row_num, line in ipairs(lines) do
                    if opts.printf then
                        if
                            line:find("__AUTO_GENERATED_PRINTF_END__$")
                            ~= nil
                        then
                            for searched_row_num = row_num, 1, -1 do
                                local searched_line = lines[searched_row_num]

                                if
                                    searched_line:find(
                                        "__AUTO_GENERATED_PRINTF_START__$"
                                    )
                                    ~= nil
                                then
                                    local region = Region:from_values(
                                        bufnr,
                                        searched_row_num,
                                        1,
                                        row_num + 1,
                                        0
                                    )
                                    table.insert(
                                        refactor.text_edits,
                                        text_edits_utils.delete_text(region)
                                    )
                                    break
                                end
                            end
                        end
                    end

                    if opts.print_var then
                        if
                            line:find("__AUTO_GENERATED_PRINT_VAR_END__$")
                            ~= nil
                        then
                            for searched_row_num = row_num, 1, -1 do
                                local searched_line = lines[searched_row_num]

                                if
                                    searched_line:find(
                                        "__AUTO_GENERATED_PRINT_VAR_START__$"
                                    )
                                    ~= nil
                                then
                                    local region = Region:from_values(
                                        bufnr,
                                        searched_row_num,
                                        1,
                                        row_num + 1,
                                        0
                                    )
                                    table.insert(
                                        refactor.text_edits,
                                        text_edits_utils.delete_text(region)
                                    )
                                    break
                                end
                            end
                        end
                    end
                end

                return true, refactor
            end
        )
        :after(tasks.post_refactor)
        :run(nil, notify.error, seed)
end

return cleanup
