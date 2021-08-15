local Path = require("plenary.path")
local scandir = require("plenary.scandir")
local refactoring = require("refactoring.refactor")
local Config = require("refactoring.config")
local test_utils = require("refactoring.tests.utils")

local extension_to_filetype = {
    ["lua"] = "lua",
    ["ts"] = "typescript",
    ["go"] = "go",
    ["py"] = "python",
}

local refactor_id_to_name = {
    ["119"] = "extract",
    ["106"] = "extract_var",
}

local cwd = vim.loop.cwd()
vim.cmd("set rtp+=" .. cwd)

local eq = assert.are.same

local function remove_cwd(file)
    return file:sub(#cwd + 2 + #"lua/refactoring/tests/")
end

local function get_refactor_name_from_path(path)
    local refactor_id = path:match("%d+")
    local refactor_name = refactor_id_to_name[tostring(refactor_id)]
    if not refactor_name then
        error(
            string.format(
                "malformed test structure: expected %s to contain a valid refactor id",
                path
            )
        )
    end
    return refactor_name
end

local function for_each_file(cb)
    local files = scandir.scan_dir(
        Path:new(cwd, "lua", "refactoring", "tests"):absolute()
    )
    for _, file in pairs(files) do
        file = remove_cwd(file)
        if string.match(file, "start") then
            cb(file)
        end
    end
end

describe("Refactoring", function()
    for_each_file(function(file)
        it(string.format("Refactoring: %s", file), function()
            local parts = test_utils.split_string(file, "%.")
            local refactor_name = get_refactor_name_from_path(parts[1])

            local contents = test_utils.split_string(
                test_utils.read_file(file),
                "\n"
            )
            local inputs = test_utils.split_string(
                test_utils.read_file(
                    string.format("%s.%s.inputs", parts[1], parts[2])
                ),
                "\n"
            )
            local commands = test_utils.split_string(
                test_utils.read_file(
                    string.format(
                        "%s.%s.%s.commands",
                        parts[1],
                        parts[2],
                        parts[4]
                    )
                ),
                "\n"
            )
            local expected = test_utils.split_string(
                test_utils.read_file(
                    string.format(
                        "%s.%s.expected.%s",
                        parts[1],
                        parts[2],
                        parts[4]
                    )
                ),
                "\n"
            )

            local bufnr = vim.api.nvim_create_buf(false, false)
            vim.api.nvim_win_set_buf(0, bufnr)
            vim.bo[bufnr].filetype = extension_to_filetype[parts[4]]
            vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, contents)
            Config.automate_input(inputs)

            for _, command in pairs(commands) do
                vim.cmd(command)
            end

            refactoring[refactor_name](bufnr)

            local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

            -- Need this for make file so that next test has clean buffer
            vim.api.nvim_buf_delete(bufnr, { force = true })

            eq(expected, lines)
        end)
    end)
end)
