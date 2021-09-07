local get_selected_locals = require("refactoring.refactor.get_selected_locals")
local utils = require("refactoring.utils")
local Pipeline = require("refactoring.pipeline")
local selection_setup = require("refactoring.tasks.selection_setup")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local get_input = require("refactoring.get_input")
local create_file = require("refactoring.tasks.create_file")
local post_refactor = require("refactoring.tasks.post_refactor")
local Config = require("refactoring.config")

local M = {}

-- 1.  We need definition set of potential captured variables

local function get_extract_setup_pipeline(bufnr)
    return Pipeline
        :from_task(refactor_setup(bufnr, Config.get_config()))
        :add_task(selection_setup)
end

local function extract_setup(refactor)

    local function_name = get_input("106: Extract Function Name > ")
    assert(function_name ~= "", "Error: Must provide function name")

    local function_body = refactor.region:get_text()
    table.insert(function_body, refactor.code["return"]("fill_me"))
    local args = vim.fn.sort(vim.tbl_keys(get_selected_locals(refactor)))

    local function_code = refactor.code["function"]({
        name = function_name,
        args = args,
        body = function_body,
    })

    refactor.text_edits = {
        {
            region = utils.region_above_node(refactor.scope),
            text = function_code,
            bufnr = refactor.buffers[2],
        },
        {
            region = refactor.region,
            text = refactor.code.constant({
                name = "fill_me",
                value = refactor.code.call_function({
                    name = function_name,
                    args = args,
                }),
            }),
        },
    }
end

M.extract_to_file = function(bufnr)
    bufnr = bufnr or vim.fn.bufnr(vim.fn.bufname())
    get_extract_setup_pipeline(bufnr)
        :add_task(create_file.from_input)
        :add_task(function(refactor)
            extract_setup(refactor)
            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

M.extract = function(bufnr)
    bufnr = bufnr or vim.fn.bufnr()
    get_extract_setup_pipeline(bufnr)
        :add_task(function(refactor)
            extract_setup(refactor)
            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return M
