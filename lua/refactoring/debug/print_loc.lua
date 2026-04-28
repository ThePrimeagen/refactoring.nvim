local api = vim.api
local ts = vim.treesitter
local async = require "async"
local iter = vim.iter
local pos = require "refactoring.pos"
local range = require "refactoring.range"

local M = {}

---@class refactor.print_loc.code_generation.Opts
---@field debug_path string
---@field count string

---@class refactor.print_loc.CodeGeneration
---@field print_loc {[string]: nil|fun(opts: refactor.print_loc.code_generation.Opts): string}

---@class refactor.print_loc.UserCodeGeneration
---@field print_loc? {[string]: nil|fun(opts: refactor.print_loc.code_generation.Opts): string}

---@class refactor.DebugPathSegmentInfo
---@field debug_path_segment TSNode
---@field text string

---@class refactor.OutputStatementInfo
---@field output_statement TSNode
---@field inside TSNode|nil
---@field inside_only boolean|nil

---@param a TSNode
---@param b TSNode
---@return boolean
local function node_comp_asc(a, b)
  local a_row, a_col, a_bytes = a:start()
  local b_row, b_col, b_bytes = b:start()
  if a_row ~= b_row then return a_row < b_row end

  return (a_col < b_col or a_col + a_bytes < b_col + b_bytes)
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param start_marker string
---@param end_marker string
local function get_all_print_loc(buf, nested_lang_tree, start_marker, end_marker)
  local query_error = require("refactoring.utils").query_error
  local get_comments = require("refactoring.utils").get_comments

  local lang = nested_lang_tree:lang()

  local comment_query = ts.query.get(lang, "refactor_comment")
  if not comment_query then return query_error("refactor_comment", lang) end

  local comments = get_comments(buf, nested_lang_tree, comment_query)
  table.sort(comments, node_comp_asc)
  ---@type vim.Range[]
  local all_print_loc = iter(comments)
    :map(
      ---@param comment TSNode
      function(comment)
        local text = ts.get_node_text(comment, buf)
        local srow, _, erow, _ = comment:range()

        local is_start = text:find(start_marker) ~= nil
        if is_start then return "start", pos(srow, 0, { buf = buf }) end
        local is_end = text:find(end_marker) ~= nil
        if is_end then return "end", pos(erow + 1, 0, { buf = buf }) end
      end
    )
    :filter(
      ---@param kind 'start'|'end'|nil
      function(kind)
        return kind ~= nil
      end
    )
    :fold(
      {},
      ---@param acc vim.Range|{current_start: vim.Pos}
      ---@param kind 'start'|'end'
      ---@param position vim.Pos
      function(acc, kind, position)
        if kind == "start" then acc.current_start = position end
        if kind == "end" and acc.current_start ~= nil then
          table.insert(acc, range(acc.current_start, position))
          acc.current_start = nil
        end

        return acc
      end
    )
  all_print_loc.current_start = nil
  return all_print_loc
end

-- TODO: maybe extract common parts of `print_loc`, `print_exp` and `print_var`
-- into a single function and simply call it with differrent params?
---@param range_type 'v' | 'V' | ''
---@param config refactor.Config
function M.print_loc(range_type, config)
  local get_selected_range = require("refactoring.utils").get_selected_range
  local code_gen_error = require("refactoring.utils").code_gen_error
  local indent = require("refactoring.utils").indent
  local apply_text_edits = require("refactoring.utils").apply_text_edits
  local get_output_statements_info = require("refactoring.utils").get_output_statements_info
  local query_error = require("refactoring.utils").query_error
  local get_debug_path_for_range = require("refactoring.utils").get_debug_path_for_range
  local get_statement_output_range = require("refactoring.debug.utils").get_statement_output_range

  local opts = config.debug.print_loc
  local code_generation = opts.code_generation

  local buf = api.nvim_get_current_buf()
  local selected_range = get_selected_range(buf, range_type)

  local task = async.run(function()
    local lang_tree, err1 = ts.get_parser(buf, nil, { error = false })
    if not lang_tree then
      ---@cast err1 -nil
      vim.notify(err1, vim.log.levels.ERROR, { title = "refactoring.nvim" })
      return
    end

    -- TODO: use async parsing
    lang_tree:parse(true)
    local nested_lang_tree = lang_tree:language_for_range {
      selected_range.start_row,
      selected_range.start_col,
      selected_range.end_row,
      selected_range.end_col,
    }
    local lang = nested_lang_tree:lang()
    local output_statement_query = ts.query.get(lang, "refactor_output_statement")
    if not output_statement_query then return query_error("refactor_output_statement", lang) end

    local get_print_loc = code_generation.print_loc[lang]
    if not get_print_loc then return code_gen_error("print_loc", lang) end

    local output_statements = get_output_statements_info(buf, nested_lang_tree, output_statement_query)

    -- NOTE: treesitter nodes usualy do not include leading whitespace
    local e_srow = selected_range:to_extmark()
    local selected_range_start_line = api.nvim_buf_get_lines(buf, e_srow, e_srow + 1, true)[1]
    local _, selected_start_line_first_non_white = selected_range_start_line:find "^%s*"
    selected_start_line_first_non_white = selected_start_line_first_non_white or 0
    local selected_reference_pos = opts.output_location == "below"
        and pos(selected_range.end_row, selected_range.end_col)
      or pos(selected_range.start_row, selected_start_line_first_non_white)
    local output_range, inserted_at =
      get_statement_output_range(buf, output_statements, opts.output_location, selected_range, selected_reference_pos)
    if not output_range or not inserted_at then return end

    local debug_path_for_range = get_debug_path_for_range(buf, nested_lang_tree, output_range)
    if not debug_path_for_range then return end
    debug_path_for_range = ("┆%s┆"):format(debug_path_for_range)

    local start_marker = config.debug.markers.print_loc.start
    local end_marker = config.debug.markers.print_loc["end"]

    local all_print_loc = get_all_print_loc(buf, nested_lang_tree, start_marker, end_marker)
    if not all_print_loc then return end
    local matching_print_loc = iter(all_print_loc)
      :filter(
        ---@param r vim.Range
        function(r)
          local srow, scol, erow, ecol = r:to_extmark()
          local r_lines = api.nvim_buf_get_text(buf, srow, scol, erow, ecol, {})
          return iter(r_lines):any(
            ---@param line string
            function(line)
              return line:find(debug_path_for_range, 1, true) ~= nil
            end
          )
        end
      )
      :totable()
    local print_loc_before = iter(matching_print_loc)
      :filter(
        ---@param r vim.Range
        function(r)
          return r < output_range
        end
      )
      :totable()

    -- TODO: commenstring isn't the correct one for injected languages
    local commentstring = vim.bo[buf].commentstring
    local print_loc_lines = {
      commentstring:format(start_marker),
      get_print_loc {
        debug_path = debug_path_for_range,
        count = ("┊%d┊"):format(#print_loc_before + 1),
      } .. commentstring:format(end_marker),
    }

    local o_srow = output_range:to_extmark()
    local expandtab = vim.bo[buf].expandtab
    local _, indent_amount = indent(expandtab, 0, api.nvim_buf_get_lines(buf, o_srow, o_srow + 1, true)[1])
    local print_text = table.concat(print_loc_lines, "\n")
    print_text = indent(expandtab, indent_amount, print_text)
    print_loc_lines = vim.split(print_text, "\n")
    if inserted_at == "end" then table.insert(print_loc_lines, 1, "") end
    if inserted_at == "start" then
      print_loc_lines[1] = indent(expandtab, 0, print_loc_lines[1])
      table.insert(print_loc_lines, (expandtab and " " or "\t"):rep(indent_amount))
    end

    ---@type {[integer]: refactor.TextEdit[]}
    local text_edits_by_buf = {}
    text_edits_by_buf[buf] = {}
    table.insert(text_edits_by_buf[buf], { range = output_range, lines = print_loc_lines })

    iter(ipairs(matching_print_loc))
      :filter(
        ---@param r vim.Range
        function(_, r)
          return r > output_range
        end
      )
      :each(
        ---@param old_count integer
        ---@param r vim.Range
        function(old_count, r)
          local srow, scol, erow, ecol = r:to_extmark()
          if ecol == 0 then
            erow = erow - 1
            ecol = #api.nvim_buf_get_lines(buf, erow, erow + 1, true)[1]
          end
          local r_lines = api.nvim_buf_get_text(buf, srow, scol, erow, ecol, {})
          ---@type integer?, string?, integer?
          local i, line, debug_path_end = iter(ipairs(r_lines))
            :map(
              ---@param i integer
              ---@param line string
              function(i, line)
                local _, e = line:find(debug_path_for_range, 1, true)
                return i, line, e
              end
            )
            :find(function(_, _, e)
              return e ~= nil
            end)
          if not i or not line or not debug_path_end then return end

          local count_start, count_end = line:find(("┊%d┊"):format(old_count), debug_path_end)
          if not count_start or not count_end then return end

          local update_count_srow = srow + i - 1
          local update_count_range =
            range(update_count_srow, count_start - 1, update_count_srow, count_end, { buf = buf })
          table.insert(
            text_edits_by_buf[buf],
            { range = update_count_range, lines = { ("┊%d┊"):format(old_count + 1) } }
          )
        end
      )

    apply_text_edits(text_edits_by_buf)
  end)
  task:raise_on_error()
end

return M
