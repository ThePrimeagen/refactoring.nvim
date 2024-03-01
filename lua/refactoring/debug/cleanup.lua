local Pipeline = require("refactoring.pipeline")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local Region = require("refactoring.region")
local text_edits_utils = require("refactoring.text_edits_utils")
local post_refactor = require("refactoring.tasks.post_refactor")

local function cleanup(bufnr, config)
    Pipeline:from_task(refactor_setup(bufnr, config))
        :add_task(
            ---@param refactor Refactor
            function(refactor)
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
                    if opts.printf then
                        if
                            string.find(line, "__AUTO_GENERATED_PRINTF_END__")
                            ~= nil
                        then
                            for searched_row_num = row_num, 1, -1 do
                                local searched_line = lines[searched_row_num]

                                if
                                    string.find(
                                        searched_line,
                                        "__AUTO_GENERATED_PRINTF_START__"
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
                            string.find(
                                line,
                                "__AUTO_GENERATED_PRINT_VAR_END__"
                            )
                            ~= nil
                        then
                            for searched_row_num = row_num, 1, -1 do
                                local searched_line = lines[searched_row_num]

                                if
                                    string.find(
                                        searched_line,
                                        "__AUTO_GENERATED_PRINT_VAR_START__"
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
        :after(post_refactor.post_refactor)
        :run()
end

return cleanup
