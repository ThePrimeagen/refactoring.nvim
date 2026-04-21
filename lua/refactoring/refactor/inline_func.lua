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
---@param definitions refactor.QfItem[]
---@param references refactor.QfItem[]
---@param lang string
---@return nil|{[integer]: refactor.inline_func.ProcessedMatchInfo}
local function get_processed_match_info(definitions, references, lang)
  local get_functions_info = require("refactoring.utils").get_functions_info
  local get_function_calls_info = require("refactoring.utils").get_function_calls_info
  local query_error = require("refactoring.utils").query_error

  local function_query = ts.query.get(lang, "refactor_function")
  if not function_query then return query_error("refactor_function", lang) end
  local function_call_query = ts.query.get(lang, "refactor_function_call")
  if not function_call_query then return query_error("refactor_function_call", lang) end

  ---@type {[integer]: refactor.inline_func.MatchInfo}
  local match_info_by_buf = iter({ definitions, references })
    :flatten(1)
    :map(
      ---@param item refactor.QfItem
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
          vim.notify(err2, vim.log.levels.ERROR)
          return
        end
        lang_tree:parse(true)

        local functions_info, returns_info = get_functions_info(buf, lang_tree, function_query)
        local function_calls_info = get_function_calls_info(buf, lang_tree, function_call_query)

        return buf,
          {
            functions = functions_info,
            function_calls = function_calls_info,
            returns = returns_info,
          }
      end
    )
    :fold(
      {},
      ---@param acc {[integer]: refactor.inline_func.MatchInfo}
      ---@param k integer
      ---@param v nil|refactor.inline_func.MatchInfo
      function(acc, k, v)
        acc[k] = v
        return acc
      end
    )

  iter(pairs(match_info_by_buf)):each(
    ---@param buf integer
    ---@param match_info refactor.inline_func.MatchInfo
    function(buf, match_info)
      iter(match_info.returns):each(
        ---@param return_info refactor.ReturnInfo
        function(return_info)
          local srow, scol, erow, ecol = return_info["return"]:range()
          local return_range = range(srow, scol, erow, ecol, { buf = buf })

          ---@type nil|refactor.ProcessedFunctionInfo
          local function_for_return = iter(match_info.functions)
            :filter(
              ---@param function_info refactor.FunctionInfo
              function(function_info)
                local f_srow, f_scol, f_erow, f_ecol = function_info["function"]:range()
                local function_range = range(f_srow, f_scol, f_erow, f_ecol, { buf = buf })
                return function_range:has(return_range)
              end
            )
            :fold(
              nil,
              ---@param acc nil|refactor.FunctionInfo
              ---@param function_info refactor.FunctionInfo
              function(acc, function_info)
                if not acc then return function_info end
                if function_info["function"]:byte_length() < acc["function"]:byte_length() then return function_info end
                return acc
              end
            )
          if not function_for_return then return end

          function_for_return.returns_info = function_for_return.returns_info or {}
          table.insert(function_for_return.returns_info, return_info)
        end
      )
    end
  )
  ---@diagnostic disable-next-line: cast-type-mismatch
  ---@cast match_info_by_buf {[integer]: refactor.inline_func.ProcessedMatchInfo}

  return match_info_by_buf
end

-- TODO: be consistent about what is singular/plural ins this kind of classes.
-- Captures will be singular, but lua structures plural
---@class refactor.ReturnInfo
---@field return TSNode
---@field values TSNode[]?

---@class refactor.FunctionInfo
---@field function TSNode
---@field outside TSNode?
---@field body TSNode[]
---@field comments TSNode[]?
---@field args TSNode[]?

---@class refactor.FunctionCallInfo
---@field function_call TSNode
---@field name TSNode
---@field args TSNode[]?
---@field return_values TSNode[]?
---@field outside TSNode?

---@class refactor.ProcessedFunctionInfo
---@field function TSNode
---@field outside TSNode?
---@field body TSNode[]
---@field comments TSNode[]?
---@field args TSNode[]?
---@field returns_info nil|refactor.ReturnInfo[]

---@class refactor.inline_func.MatchInfo
---@field functions refactor.FunctionInfo[]
---@field function_calls refactor.FunctionCallInfo[]
---@field returns refactor.ReturnInfo[]

---@class refactor.inline_func.ProcessedMatchInfo
---@field functions refactor.ProcessedFunctionInfo[]
---@field function_calls refactor.FunctionCallInfo[]
---@field returns refactor.ReturnInfo[]

---@param config refactor.Config
function M.inline_func(_, config)
  local apply_text_edits = require("refactoring.utils").apply_text_edits
  local code_gen_error = require("refactoring.utils").code_gen_error
  local select = require("refactoring.utils").select
  local indent = require("refactoring.utils").indent
  local get_definitions = require("refactoring.utils").get_definitions
  local get_references = require("refactoring.utils").get_references

  local opts = config.refactor.inline_func
  local code_generation = opts.code_generation

  local lang_tree, err1 = ts.get_parser(nil, nil, { error = false })
  if not lang_tree then
    ---@cast err1 -nil
    vim.notify(err1, vim.log.levels.ERROR)
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

  local task = async.run(function()
    local results = async.await_all {
      async.run(get_definitions),
      async.run(get_references),
    }
    local definitions = unpack(results[1]) ---@type refactor.QfItem[]
    local references = unpack(results[2]) ---@type refactor.QfItem[]

    local match_info_by_buf = get_processed_match_info(definitions, references, lang)
    if not match_info_by_buf then return end

    ---@class refactor.inline_func.DefinitionWithFunctionInfo
    ---@field definition refactor.QfItem
    ---@field function_info refactor.ProcessedFunctionInfo

    ---@type refactor.inline_func.DefinitionWithFunctionInfo[]
    local definitions_with_function_info = iter(definitions)
      :map(
        ---@param d refactor.QfItem
        function(d)
          local buf = vim.fn.bufadd(d.filename)

          local match_info = match_info_by_buf[buf]
          -- TODO: add range.vimscript
          local d_range = range(d.lnum - 1, d.col - 1, d.end_lnum - 1, d.end_col - 1, { buf = buf })
          local function_info = iter(match_info.functions):find(
            ---@param function_info refactor.FunctionInfo
            function(function_info)
              local srow, scol, erow, ecol = function_info["function"]:range()
              local function_range = range(srow, scol, erow, ecol, { buf = buf })
              return function_range:has(d_range)
            end
          )

          return { definition = d, function_info = function_info }
        end
      )
      :filter(
        ---@param definition_with_function_info refactor.inline_func.DefinitionWithFunctionInfo
        function(definition_with_function_info)
          return definition_with_function_info.function_info ~= nil
        end
      )
      :totable()

    if #definitions_with_function_info == 0 then
      vim.notify("Couldn't find the definition of the symbol under cursor using treesitter", vim.log.levels.ERROR)
      return
    end
    local definition_with_function_info = #definitions_with_function_info == 1 and definitions_with_function_info[1]
      or select(definitions_with_function_info, {
        prompt = "Multiple definitions found, select one",
        format_item =
          ---@param item refactor.inline_func.DefinitionWithFunctionInfo
          function(item)
            local buf = vim.fn.bufadd(item.definition.filename)
            return ts.get_node_text(item.function_info["function"], buf)
          end,
      })
    if not definition_with_function_info then return end

    local definition, function_info =
      definition_with_function_info.definition, definition_with_function_info.function_info
    local in_buf = vim.fn.bufadd(definition.filename)
    if function_info.returns_info and #function_info.returns_info > 1 then
      vim.notify("The function has multiple return statements", vim.log.levels.WARN)
      return
    end

    ---@class refactor.inline_func.ReferenceWithFunctionCallInfo
    ---@field reference refactor.QfItem
    ---@field function_call_info refactor.FunctionCallInfo

    -- TODO: some LSPs (like lua_ls) may give a reference to a symbol that is
    -- not a function_call (i.e. the variable declaration on `require`). Maybe
    -- give a warning and do nothing if there are no
    -- `references_with_function_call_info` (?
    ---@type refactor.inline_func.ReferenceWithFunctionCallInfo[]
    local references_with_function_call_info = iter(references)
      :map(
        ---@param r refactor.QfItem
        function(r)
          local buf = vim.fn.bufadd(r.filename)

          local match_info = match_info_by_buf[buf]
          -- TODO: add range.vimscript
          local r_range = range(r.lnum - 1, r.col - 1, r.end_lnum - 1, r.end_col - 1, { buf = buf })
          local function_call_info = iter(match_info.function_calls):find(
            ---@param function_call_info refactor.FunctionCallInfo
            function(function_call_info)
              local srow, scol, erow, ecol = function_call_info.function_call:range()
              local function_call_range = range(srow, scol, erow, ecol, { buf = buf })
              return function_call_range:has(r_range)
            end
          )

          return { reference = r, function_call_info = function_call_info }
        end
      )
      :filter(
        ---@param reference_with_function_call_info refactor.inline_func.ReferenceWithFunctionCallInfo
        function(reference_with_function_call_info)
          return reference_with_function_call_info.function_call_info ~= nil
        end
      )
      :totable()

    local body_start_row, body_start_col = function_info.body[1]:start()
    local body_end_row, body_end_col ---@type integer, integer
    if not function_info.returns_info or #function_info.returns_info == 0 then
      body_end_row, body_end_col = function_info.body[#function_info.body]:end_()
    else
      body_end_row, body_end_col = function_info.returns_info[1]["return"]:start()
    end
    local body_range = range(body_start_row, body_start_col, body_end_row, body_end_col, { buf = in_buf })
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
    local args = function_info.args
      and iter(function_info.args)
        :map(
          ---@param arg TSNode
          function(arg)
            return ts.get_node_text(arg, in_buf)
          end
        )
        :totable()
    local function_return_values = (function_info.returns_info and function_info.returns_info[1].values)
      and iter(function_info.returns_info[1].values)
        :map(
          ---@param return_value TSNode
          function(return_value)
            return ts.get_node_text(return_value, in_buf)
          end
        )
        :totable()

    ---@type {[integer]: refactor.TextEdit[]}
    local text_edits_by_buf = {}
    iter(references_with_function_call_info):each(
      ---@param r refactor.inline_func.ReferenceWithFunctionCallInfo
      function(r)
        local out_buf = vim.fn.bufadd(r.reference.filename)
        local inlined_function_lines = {} ---@type string[]

        if args or r.function_call_info.args then
          local params = r.function_call_info.args
            and iter(r.function_call_info.args)
              :map(
                ---@param arg TSNode
                function(arg)
                  return ts.get_node_text(arg, out_buf)
                end
              )
              :totable()
          -- TODO: check if args[i] == params[i] and remove both of the from the
          -- lists if true
          local args_assignment = get_assignment {
            left = args or {},
            right = params or {},
          }
          vim.list_extend(inlined_function_lines, vim.split(args_assignment, "\n"))
        end

        local srow, scol, erow, ecol = (r.function_call_info.outside or r.function_call_info.function_call):range()
        local fc_range = range(srow, scol, erow, ecol, { buf = in_buf })
        local fc_start_row, _, fc_end_row = fc_range:to_extmark()
        local function_call = table.concat(api.nvim_buf_get_lines(out_buf, fc_start_row, fc_end_row, true), "\n")

        local _, indent_amount = indent(vim.bo[out_buf].expandtab, 0, function_call)
        local indented_body_without_return = indent(vim.bo[out_buf].expandtab, indent_amount, body_without_return)
        vim.list_extend(inlined_function_lines, vim.split(indented_body_without_return, "\n"))

        if function_return_values or r.function_call_info.return_values then
          local function_call_return_values = r.function_call_info.return_values
            and iter(r.function_call_info.return_values)
              :map(
                ---@param return_value TSNode
                function(return_value)
                  return ts.get_node_text(return_value, out_buf)
                end
              )
              :totable()
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

    local srow, scol, erow, ecol = (function_info.outside or function_info["function"]):range()
    -- NOTE: deletes whole line instead of leaving an empty line
    if ecol > 0 and ecol == #api.nvim_buf_get_lines(0, erow, erow + 1, true)[1] then
      erow = erow + 1
      ecol = 0
    end
    local function_range = range(srow, scol, erow, ecol, { buf = in_buf })
    if function_info.comments then
      local f_srow, f_scol, f_erow, f_ecol = function_info.comments[1]:range()
      local highest_comment_range = range(f_srow, f_scol, f_erow, f_ecol, { buf = in_buf })
      function_range.start_row, function_range.start_col =
        highest_comment_range.start_row, highest_comment_range.start_col
    end

    text_edits_by_buf[in_buf] = text_edits_by_buf[in_buf] or {}
    table.insert(text_edits_by_buf[in_buf], {
      range = function_range,
      lines = {},
    })

    apply_text_edits(text_edits_by_buf)
  end)
  task:raise_on_error()
  if opts.preview_ns then task:wait() end
end

return M
