local dev = require("refactoring.dev")
dev.reload()

local Region = require("refactoring.region")
local ts_utils = require("nvim-treesitter.ts_utils")
local utils = require("refactoring.utils")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.pipeline.selection_setup")

local REFACTORING = {}
local REFACTORING_OPTIONS = {
    code_generation = {
        lua = {
            extract_function = function(opts)
                return {
                    create = string.format(
                        [[
                    local function %s(%s)
                    %s
                    return %s
                end
                ]],
                        opts.name,
                        table.concat(opts.args, ", "),
                        type(opts.body) == "table"
                                and table.concat(opts.body, "\n")
                            or opts.body,
                        opts.ret
                    ),

                    call = string.format(
                        "local %s = %s(%s)",
                        opts.ret,
                        opts.name,
                        table.concat(opts.args, ", ")
                    ),
                }
            end,
        },
    },
}

-- 106
local function get_text_edits(
    selected_local_references,
    region,
    lang,
    scope_region,
    function_name,
    ret
)
    -- local declaration within the selection range.
    local lsp_text_edits = {}
    local extract_function =
        REFACTORING_OPTIONS.code_generation[lang].extract_function({
            args = vim.tbl_keys(selected_local_references),
            body = region:get_text(),
            name = function_name,
            ret = ret,
        })
    table.insert(lsp_text_edits, {
        range = scope_region:to_lsp_range(),
        newText = string.format("\n%s", extract_function.create),
    })
    table.insert(lsp_text_edits, {
        range = region:to_lsp_range(),
        newText = string.format("\n%s", extract_function.call),
    })
    return lsp_text_edits
end

local function get_local_definitions(local_defs, function_args)
    local local_def_map = {}

    for _, def in pairs(local_defs) do
        local_def_map[ts_utils.get_node_text(def)[1]] = true
    end

    for _, def in pairs(function_args) do
        local_def_map[ts_utils.get_node_text(def)[1]] = true
    end

    return local_def_map
end

local function get_top_of_scope_region(scope)
    local scope_region = Region:from_node(scope)
    local lsp_range = scope_region:to_lsp_range()
    lsp_range.start.line = math.max(lsp_range.start.line - 1, 0)
    lsp_range["end"] = lsp_range.start

    return Region:from_lsp_range(lsp_range)
end

REFACTORING.extract = function(bufnr)
    Pipeline
        :from_task(selection_setup(bufnr))
        :add_task(function(refactor)
            if refactor.scope == nil then
                return false, "Scope is nil"
            end

            local local_defs = vim.tbl_filter(function(node)
                return not utils.range_contains_node(node, refactor.region:to_ts())
            end, utils.get_locals_defs(
                refactor.scope,
                refactor.lang
            ))

            local function_args = utils.get_function_args(refactor.scope, refactor.lang)
            local local_def_map = get_local_definitions(
                local_defs,
                function_args
            )
            local local_references = utils.get_all_identifiers(refactor.scope, refactor.lang)
            local selected_local_references = {}

            for _, local_ref in pairs(local_references) do
                local local_name = ts_utils.get_node_text(local_ref)[1]
                if
                    utils.range_contains_node(local_ref, refactor.region:to_ts())
                    and local_def_map[local_name]
                then
                    selected_local_references[local_name] = true
                end
            end

            -- TODO: Probably use text edit
            local scope_region = get_top_of_scope_region(refactor.scope)

            -- TODO: Polar, nvim_buf_get_lines doesn't actually get the highlighted
            -- region, instead the highlighted rows
            local function_name = vim.fn.input("106: Extract Function Name > ")

            --[[
            local first_local_def_name = ts_utils.get_node_text(
            utils.get_locals_defs(refactor.scope, refactor.lang)[1],
            0
            )[1]
            --]]

            -- TODO: Polor, could you also make the variable that is returned the first
            local text_edits = get_text_edits(
                selected_local_references,
                refactor.region,
                refactor.lang,
                scope_region,
                function_name,
                "fill me in daddy"
            )

            vim.lsp.util.apply_text_edits(text_edits, 0)
            -- TODO: Ensure indenting is correct
            vim.cmd([[ :norm! gg=G ]])

            return true, "I am result"
        end)
        :run(function(ok, result)
            print("Success!!", ok, result)
        end)
end

return REFACTORING
