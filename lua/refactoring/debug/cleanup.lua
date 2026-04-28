local api = vim.api
local iter = vim.iter
local async = require "async"
local range = require "refactoring.range"
local pos = require "refactoring.pos"
local ts = vim.treesitter

-- TODO: Search inside strings (using treesitter) on `printf` (and
-- maybe also `print_var`) when updating the count. That would mean
-- decoupling the `code_generation` for the content of the string and
-- the whole print statement

local M = {}

---@param a TSNode
---@param b TSNode
---@return boolean
local function node_comp_asc(a, b)
  local a_row, a_col, a_bytes = a:start()
  local b_row, b_col, b_bytes = b:start()
  if a_row ~= b_row then return a_row < b_row end

  return (a_col < b_col or a_col + a_bytes < b_col + b_bytes)
end

---@param range_type 'v' | 'V' | ''
---@param config refactor.Config
function M.cleanup(range_type, config)
  local get_selected_range = require("refactoring.utils").get_selected_range
  local apply_text_edits = require("refactoring.utils").apply_text_edits
  local get_comments = require("refactoring.utils").get_comments
  local query_error = require("refactoring.utils").query_error

  local opts = config.debug.cleanup

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
    local comment_query = ts.query.get(lang, "refactor_comment")
    if not comment_query then return query_error("refactor_comment", lang) end

    local comments = get_comments(buf, nested_lang_tree, comment_query)
    table.sort(comments, node_comp_asc)
    ---@type vim.Range[]
    local ranges_to_cleanup = iter(comments)
      :filter(
        ---@param comment TSNode
        function(comment)
          local srow, scol, erow, ecol = comment:range()
          local comment_range = range(buf, srow, scol, erow, ecol)
          return selected_range:has(comment_range)
        end
      )
      :map(
        ---@param comment TSNode
        function(comment)
          local text = ts.get_node_text(comment, buf)
          local srow, _, erow, _ = comment:range()

          local is_start = iter(opts.types):any(
            ---@param name 'print_var'|'print_loc'|'print_exp'
            function(name)
              return text:find(config.debug.markers[name].start) ~= nil
            end
          )
          if is_start then return "start", pos(buf, srow, 0) end
          local is_end = iter(opts.types):any(
            ---@param name 'print_var'|'print_loc'|'print_exp'
            function(name)
              return text:find(config.debug.markers[name]["end"]) ~= nil
            end
          )
          if is_end then return "end", pos(buf, erow + 1, 0) end
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
        ---@param acc vim.Range[]|{current_start: vim.Pos}
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

    ---@type {[integer]: refactor.TextEdit[]}
    local text_edits_by_buf = {}
    text_edits_by_buf[buf] = {}
    iter(ipairs(ranges_to_cleanup)):each(
      ---@param r vim.Range
      function(_, r)
        table.insert(text_edits_by_buf[buf], { range = r, lines = {} })
      end
    )

    apply_text_edits(text_edits_by_buf)
    if config.show_success_message then
      vim.notify(
        ("Cleaned up %d print-debugs"):format(#ranges_to_cleanup),
        vim.log.levels.INFO,
        { title = "refactoring.nvim" }
      )
    end

    local last_view = require("refactoring.debug")._last_view
    if opts.restore_view and last_view then vim.fn.winrestview(last_view) end
  end)
  task:raise_on_error()
end

return M
