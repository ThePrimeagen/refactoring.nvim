local async = require "async"
local range = require "refactoring.range"
local ts = vim.treesitter
local api = vim.api
local iter = vim.iter

local M = {}

-- TODO: support type inference?
---@class refactor.inline_func.code_generation.assignment.Opts
---@field left string[]
---@field right string[]

---@class refactor.inline_func.CodeGeneration
---@field assignment {[string]: nil|fun(opts: refactor.inline_func.code_generation.assignment.Opts): string}

---@class refactor.inline_func.UserCodeGeneration
---@field assignment? {[string]: nil|fun(opts: refactor.inline_func.code_generation.assignment.Opts): string}

--As a side effect, loads all the buffers for all of the definitions and references
---@param definitions vim.quickfix.entry[]
---@param references vim.quickfix.entry[]
---@param lang string
---@return nil|{[integer]: refactor.inline_func.ProcessedMatch}
local function get_processed_match(definitions, references, lang)
  local get_functions = require("refactoring.utils").get_functions
  local get_function_calls = require("refactoring.utils").get_function_calls
  local query_error = require("refactoring.utils").query_error

  local function_query = ts.query.get(lang, "refactor_function")
  if not function_query then return query_error("refactor_function", lang) end
  local function_call_query = ts.query.get(lang, "refactor_function_call")
  if not function_call_query then return query_error("refactor_function_call", lang) end

  ---@type {[integer]: refactor.inline_func.Match}
  local match_by_buf = iter({ definitions, references })
    :flatten(1)
    :map(
      ---@param item vim.quickfix.entry
      function(item)
        local buf = vim.fn.bufadd(item.filename)
        if not api.nvim_buf_is_loaded(buf) then vim.fn.bufload(buf) end
        return buf
      end
    )
    :unique()
    :map(
      ---@param buf integer
      function(buf)
        local lang_tree, err2 = ts.get_parser(buf, lang, { error = false })
        if not lang_tree then
          ---@cast err2 -nil
          vim.notify(err2, vim.log.levels.ERROR, { title = "refactoring.nvim" })
          return
        end
        lang_tree:parse(true)

        local functions, returns = get_functions(buf, lang_tree, function_query)
        local function_calls = get_function_calls(buf, lang_tree, function_call_query)

        return buf,
          {
            functions = functions,
            function_calls = function_calls,
            returns = returns,
          }
      end
    )
    :fold(
      {},
      ---@param acc {[integer]: refactor.inline_func.Match}
      ---@param k integer
      ---@param v nil|refactor.inline_func.Match
      function(acc, k, v)
        acc[k] = v
        return acc
      end
    )

  iter(pairs(match_by_buf)):each(
    ---@param buf integer
    ---@param match refactor.inline_func.Match
    function(buf, match)
      iter(match.returns):each(
        ---@param return_ refactor.Return
        function(return_)
          local return_range = range(buf, return_["return"]:range())

          ---@type nil|refactor.ProcessedFunction
          local function_for_return = iter(match.functions)
            :filter(
              ---@param function_ refactor.Function
              function(function_)
                local function_range = range(buf, function_["function"]:range())
                return function_range:has(return_range)
              end
            )
            :fold(
              nil,
              ---@param acc nil|refactor.Function
              ---@param function_ refactor.Function
              function(acc, function_)
                if not acc then return function_ end
                if function_["function"]:byte_length() < acc["function"]:byte_length() then return function_ end
                return acc
              end
            )
          if not function_for_return then return end

          function_for_return.returns = function_for_return.returns or {}
          table.insert(function_for_return.returns, return_)
        end
      )
    end
  )
  ---@diagnostic disable-next-line: cast-type-mismatch
  ---@cast match_by_buf {[integer]: refactor.inline_func.ProcessedMatch}

  return match_by_buf
end

-- TODO: be consistent about what is singular/plural ins this kind of classes.
-- Captures will be singular, but lua structures plural
---@class refactor.Return
---@field return TSNode
---@field values TSNode[]?

---@class refactor.Function
---@field function TSNode
---@field outside TSNode?
---@field body TSNode[]
---@field comments TSNode[]?
---@field args TSNode[]?

---@class refactor.FunctionCall
---@field function_call TSNode
---@field name TSNode
---@field args TSNode[]?
---@field return_values TSNode[]?
---@field outside TSNode?

---@class refactor.ProcessedFunction
---@field function TSNode
---@field outside TSNode?
---@field body TSNode[]
---@field comments TSNode[]?
---@field args TSNode[]?
---@field returns nil|refactor.Return[]

---@class refactor.inline_func.Match
---@field functions refactor.Function[]
---@field function_calls refactor.FunctionCall[]
---@field returns refactor.Return[]

---@class refactor.inline_func.ProcessedMatch
---@field functions refactor.ProcessedFunction[]
---@field function_calls refactor.FunctionCall[]
---@field returns refactor.Return[]

---@param config refactor.Config
function M.inline_func(_, config)
  local apply_text_edits = require("refactoring.utils").apply_text_edits
  local code_gen_error = require("refactoring.utils").code_gen_error
  local select = require("refactoring.utils").select
  local indent = require("refactoring.utils").indent
  local get_lsp_definitions = require("refactoring.utils").get_lsp_definitions
  local get_lsp_references = require("refactoring.utils").get_lsp_references

  local opts = config.refactor.inline_func
  local code_generation = opts.code_generation

  local lang_tree, err1 = ts.get_parser(nil, nil, { error = false })
  if not lang_tree then
    ---@cast err1 -nil
    vim.notify(err1, vim.log.levels.ERROR, { title = "refactoring.nvim" })
    return
  end
  -- TODO: use async parsing
  lang_tree:parse(true)
  local cursor = api.nvim_win_get_cursor(0)
  local nested_lang_tree = lang_tree:language_for_range {
    cursor[1] - 1,
    cursor[2],
    cursor[1] - 1,
    cursor[2],
  }
  local lang = nested_lang_tree:lang()

  local get_assignment = code_generation.assignment[lang]
  if not get_assignment then return code_gen_error("assignment", lang) end

  local is_preview = opts.preview_ns ~= nil
  local task = async.run(function()
    local results = async.await_all {
      async.run(get_lsp_definitions, is_preview),
      async.run(get_lsp_references, is_preview),
    }
    local lsp_definitions = unpack(results[1]) ---@type vim.quickfix.entry[]
    local lsp_references = unpack(results[2]) ---@type vim.quickfix.entry[]

    local match_by_buf = get_processed_match(lsp_definitions, lsp_references, lang)
    if not match_by_buf then return end

    ---@class refactor.inline_func.DefinitionWithFunction
    ---@field definition vim.quickfix.entry
    ---@field function_ refactor.ProcessedFunction

    ---@type refactor.inline_func.DefinitionWithFunction[]
    local definitions_with_function = iter(lsp_definitions)
      :map(
        ---@param d vim.quickfix.entry
        function(d)
          local buf = vim.fn.bufadd(d.filename)

          local match = match_by_buf[buf]
          -- TODO: add range.vimscript
          local d_range = range(buf, d.lnum - 1, d.col - 1, d.end_lnum - 1, d.end_col - 1)
          local function_ = iter(match.functions):find(
            ---@param function_ refactor.Function
            function(function_)
              local function_range = range(buf, function_["function"]:range())
              return function_range:has(d_range)
            end
          )

          return { definition = d, function_ = function_ }
        end
      )
      :filter(
        ---@param definition_with_function refactor.inline_func.DefinitionWithFunction
        function(definition_with_function)
          return definition_with_function.function_ ~= nil
        end
      )
      :totable()

    if #definitions_with_function == 0 then
      vim.notify(
        "Couldn't find the definition of the symbol under cursor using treesitter",
        vim.log.levels.ERROR,
        { title = "refactoring.nvim" }
      )
      return
    end
    local definition_with_function = #definitions_with_function == 1 and definitions_with_function[1]
      or select(definitions_with_function, {
        prompt = "Multiple definitions found, select one",
        format_item =
          ---@param item refactor.inline_func.DefinitionWithFunction
          function(item)
            local buf = vim.fn.bufadd(item.definition.filename)
            return ts.get_node_text(item.function_["function"], buf)
          end,
      })
    if not definition_with_function then return end

    local definition, function_ = definition_with_function.definition, definition_with_function.function_
    local in_buf = vim.fn.bufadd(definition.filename)
    if function_.returns and #function_.returns > 1 then
      vim.notify("The function has multiple return statements", vim.log.levels.ERROR, { title = "refactoring.nvim" })
      return
    end

    ---@class refactor.inline_func.ReferenceWithFunctionCall
    ---@field reference vim.quickfix.entry
    ---@field function_call refactor.FunctionCall

    -- TODO: some LSPs (like lua_ls) may give a reference to a symbol that is
    -- not a function_call (i.e. the variable declaration on `require`). Maybe
    -- give a warning and do nothing if there are no
    -- `references_with_function_call` (?
    ---@type refactor.inline_func.ReferenceWithFunctionCall[]
    local references_with_function_call = iter(lsp_references)
      :map(
        ---@param r vim.quickfix.entry
        function(r)
          local buf = vim.fn.bufadd(r.filename)

          local match = match_by_buf[buf]
          -- TODO: add range.vimscript
          local r_range = range(buf, r.lnum - 1, r.col - 1, r.end_lnum - 1, r.end_col - 1)
          local function_call = iter(match.function_calls):find(
            ---@param function_call refactor.FunctionCall
            function(function_call)
              local function_call_range = range(buf, function_call.function_call:range())
              return function_call_range:has(r_range)
            end
          )

          return { reference = r, function_call = function_call }
        end
      )
      :filter(
        ---@param reference_with_function_call refactor.inline_func.ReferenceWithFunctionCall
        function(reference_with_function_call)
          return reference_with_function_call.function_call ~= nil
        end
      )
      :totable()

    local body_start_row, body_start_col = function_.body[1]:start()
    local body_end_row, body_end_col ---@type integer, integer
    if not function_.returns or #function_.returns == 0 then
      body_end_row, body_end_col = function_.body[#function_.body]:end_()
    else
      body_end_row, body_end_col = function_.returns[1]["return"]:start()
    end
    local body_range = range(in_buf, body_start_row, body_start_col, body_end_row, body_end_col)
    local b_srow, b_scol, b_erow, b_ecol = body_range:to_extmark()

    local body_lines_without_return = api.nvim_buf_get_text(in_buf, b_srow, b_scol, b_erow, b_ecol, {})
    -- NOTE: can't use `indent()` because first line may not have any indent because of treesitter
    -- TODO: use `indent()` without the first line and then add the first line
    local body_without_return = iter(body_lines_without_return)
      :map(
        ---@param line string
        function(line)
          local dedented = line:gsub("^(%s*)", "")
          return dedented
        end
      )
      :join "\n"
    local args = function_.args
      and iter(function_.args)
        :map(
          ---@param arg TSNode
          function(arg)
            return ts.get_node_text(arg, in_buf)
          end
        )
        :totable()
    local function_return_values = (function_.returns and function_.returns[1].values)
      and iter(function_.returns[1].values)
        :map(
          ---@param return_value TSNode
          function(return_value)
            return ts.get_node_text(return_value, in_buf)
          end
        )
        :totable()

    ---@type {[integer]: refactor.TextEdit[]}
    local text_edits_by_buf = {}
    iter(references_with_function_call):each(
      ---@param r refactor.inline_func.ReferenceWithFunctionCall
      function(r)
        local out_buf = vim.fn.bufadd(r.reference.filename)
        local inlined_function_lines = {} ---@type string[]

        if args or r.function_call.args then
          local params = r.function_call.args
              and iter(r.function_call.args)
                :map(
                  ---@param arg TSNode
                  function(arg)
                    return ts.get_node_text(arg, out_buf)
                  end
                )
                :totable()
            or {}
          for i = #params, 1, -1 do
            if args and args[i] == params[i] then
              table.remove(args, i)
              table.remove(params, i)
            end
          end
          local args_assignment = get_assignment {
            left = args or {},
            right = params or {},
          }
          vim.list_extend(inlined_function_lines, vim.split(args_assignment, "\n"))
        end

        local fc_range = range(in_buf, (r.function_call.outside or r.function_call.function_call):range())
        local fc_start_row, _, fc_end_row = fc_range:to_extmark()
        local function_call = table.concat(api.nvim_buf_get_lines(out_buf, fc_start_row, fc_end_row, true), "\n")

        local _, indent_amount = indent(vim.bo[out_buf].expandtab, 0, function_call)
        local indented_body_without_return = indent(vim.bo[out_buf].expandtab, indent_amount, body_without_return)
        vim.list_extend(inlined_function_lines, vim.split(indented_body_without_return, "\n"))

        if function_return_values or r.function_call.return_values then
          local function_call_return_values = r.function_call.return_values
              and iter(r.function_call.return_values)
                :map(
                  ---@param return_value TSNode
                  function(return_value)
                    return ts.get_node_text(return_value, out_buf)
                  end
                )
                :totable()
            or {}
          for i = #function_call_return_values, 1, -1 do
            if function_return_values and function_return_values[i] == function_call_return_values[i] then
              table.remove(function_return_values, i)
              table.remove(function_call_return_values, i)
            end
          end
          local return_values_assignment = get_assignment {
            left = function_call_return_values or {},
            right = function_return_values or {},
          }
          vim.list_extend(inlined_function_lines, vim.split(return_values_assignment, "\n"))
        end

        text_edits_by_buf[out_buf] = text_edits_by_buf[out_buf] or {}
        table.insert(text_edits_by_buf[out_buf], {
          range = fc_range,
          lines = inlined_function_lines,
        })
      end
    )

    local srow, scol, erow, ecol = (function_.outside or function_["function"]):range()
    -- NOTE: deletes whole line instead of leaving an empty line
    if ecol > 0 and ecol == #api.nvim_buf_get_lines(0, erow, erow + 1, true)[1] then
      erow = erow + 1
      ecol = 0
    end
    local function_range = range(in_buf, srow, scol, erow, ecol)
    if function_.comments then
      local highest_comment_range = range(in_buf, function_.comments[1]:range())
      function_range.start_row, function_range.start_col =
        highest_comment_range.start_row, highest_comment_range.start_col
    end

    text_edits_by_buf[in_buf] = text_edits_by_buf[in_buf] or {}
    table.insert(text_edits_by_buf[in_buf], {
      range = function_range,
      lines = {},
    })

    apply_text_edits(text_edits_by_buf)
    if config.show_success_message then
      vim.notify(
        ("Inlined %d function occurrences"):format(#references_with_function_call),
        vim.log.levels.INFO,
        { title = "refactoring.nvim" }
      )
    end
  end)
  task:raise_on_error()
  if is_preview then task:wait() end
end

return M
