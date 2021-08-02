local scandir = require("plenary.scandir")
local Path = require("plenary.path")
local refactoring = require("refactoring.refactor")
local Config = require("refactoring.config")

local cwd = vim.loop.cwd()
vim.cmd("set rtp+=" .. cwd)

local eq = assert.are.same

local function remove_cwd(file)
    return file:sub(#cwd + 2 + #"lua/refactoring/tests/")
end

local function split_string(inputstr, sep)
    local t = {}
    -- [[ lets not think about the edge case there... --]]
    while #inputstr > 0 do
        local start, stop = inputstr:find(sep)
        local str
        if not start then
            str = inputstr
            inputstr = ""
        else
            str = inputstr:sub(1, start - 1)
            inputstr = inputstr:sub(stop + 1)
        end
        table.insert(t, str)
    end
    return t
end

local function read_file(file)
    return Path:new("lua", "refactoring", "tests", file):read()
end

local extension_to_filetype = {
    ["lua"] = "lua",
    ["ts"] = "typescript",
}

describe("Refactoring", function()
    it("All refactoring", function()
        local files = scandir.scan_dir(
            Path:new(cwd, "lua", "refactoring", "tests"):absolute()
        )
        for _, file in pairs(files) do
            file = remove_cwd(file)
            if string.match(file, "start") then
                local parts = split_string(file, "%.")

                if not refactoring[parts[1]] then
                    error(
                        string.format(
                            "malformed test file: expected %s to be a valid refactor",
                            refactoring[parts[1]]
                        )
                    )
                end

                local contents = split_string(read_file(file), "\n")
                local inputs = split_string(
                    read_file(string.format("%s.%s.inputs", parts[1], parts[2])),
                    "\n"
                )
                local commands = split_string(
                    read_file(
                        string.format("%s.%s.commands", parts[1], parts[2])
                    ),
                    "\n"
                )
                local expected = split_string(
                    read_file(
                        string.format(
                            "%s.%s.expected.%s",
                            parts[1],
                            parts[2],
                            parts[4]
                        )
                    ),
                    "\n"
                )

                vim.cmd(":new")
                vim.cmd(string.format(":set filetype=%s", extension_to_filetype[parts[4]]))
                vim.api.nvim_buf_set_lines(0, 0, -1, false, contents)
                Config.automate_input(inputs)

                for _, command in pairs(commands) do
                    vim.cmd(command)
                end

                refactoring[parts[1]](0)

                local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                eq(expected, lines)
            end
        end
    end)
end)
