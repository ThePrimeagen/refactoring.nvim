local Pipeline = require("refactoring.pipeline")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local post_refactor = require("refactoring.tasks.post_refactor")
local ts = require("refactoring.ts")
local Region = require("refactoring.region")
local lsp_utils = require("refactoring.lsp_utils")
local ts_utils = require("nvim-treesitter.ts_utils")

local function dump(o)
    if type(o) == "table" then
        local s = "{ "
        for k, v in pairs(o) do
            if type(k) ~= "number" then
                k = '"' .. k .. '"'
            end
            s = s .. "[" .. k .. "] = " .. dump(v) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

local function dumpcode(o)
    if type(o) == "table" then
        local out = {}
        for idx, identifier in pairs(o) do
            local region = Region:from_node(identifier)
            local parameter_list = region:get_text()
            table.insert(out, idx, parameter_list)
        end
        return dump(out)
    else
        local region = Region:from_node(o)
        local parameter_list = region:get_text()
        return dump(parameter_list)
    end
end

local function pdebug(o)
    print("INLINE_FUNC_DEBUG")
    print(dump(o))
    print("")
end


local M = {}

local function get_inline_setup_pipeline(bufnr, opts)
    return Pipeline:from_task(refactor_setup(bufnr, opts))
    -- :add_task(selection_setup)
end

local function determine_declarator_node(refactor, bufnr)
    -- only deal with first declaration
    local declarator_node = refactor.ts:local_declarations_under_cursor(
        refactor.scope,
        refactor.region
    )

    if declarator_node then
        return declarator_node
    else
        local current_node = ts.get_node_at_cursor(0)
        local declaration = ts.find_declaration(current_node, bufnr)
        if declaration ~= nil then
            return declaration
        end

        local definition = ts.find_definition(current_node, bufnr)
        declarator_node = refactor.ts.get_container(definition, refactor.ts.function_declaration)
        return declarator_node
    end
end

local function inline_func_setup(refactor, bufnr)
    local declarator_node = determine_declarator_node(refactor, bufnr)

    local references =
        ts.find_references(declarator_node, refactor.scope, bufnr)

    if #references < 2 then
        error("Error: no function usages to inline")
        return
    end

    local text_edits = {}
    -- TODO: find and delete the function declaration

    -- print(dump(declarator_node:parent():type()))
    -- print(vim.inspect(utils.get_node_text(declarator_node:parent())))

    local function_text
    for _, value in ipairs(refactor.ts:get_function_body(declarator_node:parent())) do
        function_text = vim.treesitter.get_node_text(value, bufnr)
    end

    -- replaces all references with inner function text
    local node_at_point = ts.get_node_at_cursor()
    local lsp_range = ts_utils.node_to_lsp_range(node_at_point:parent())
    local text_edit = { range = lsp_range, newText = function_text }
    table.insert(text_edits, text_edit)

    -- detele the original function
    table.insert(
        text_edits,
        lsp_utils.delete_text(Region:from_node(declarator_node:parent(), bufnr))
    )
    refactor.text_edits = text_edits
end

---@param bufnr number
---@param opts table
function M.inline_func(bufnr, opts)
    print("from inline_func")
    get_inline_setup_pipeline(bufnr, opts)
        :add_task(
        --- @param refactor Refactor
            function(refactor)
                inline_func_setup(refactor, bufnr)
                return true, refactor
            end
        )
        :after(post_refactor.post_refactor)
        :run()
end

return M
