local range = require "refactoring.range"
local iter = vim.iter
local api = vim.api

local M = {}

---@param output_range vim.Range
---@param buf integer
---@return boolean, integer|nil
local function get_has_indent_before(output_range, buf)
  local s_srow = output_range:to_extmark()
  local output_line = api.nvim_buf_get_lines(buf, s_srow, s_srow + 1, true)[1]
  local s, e = output_line:find "%s+"
  local space_start, space_end ---@type integer|nil, integer|nil
  while s and e do
    s, e = output_line:find("%s+", e + 1)
    if e and e > output_range.start_col then break end
    space_start, space_end = s, e
  end
  if not space_start or not space_end then return false, nil end

  local space_length = space_end - space_start + 1
  local indent_width = vim.bo[buf].shiftwidth > 0 and vim.bo[buf].shiftwidth or vim.bo[buf].tabstop
  local has_indent_before = math.floor(space_length / indent_width) > 0

  return has_indent_before, space_start
end

---@param buf integer
---@param output_statements refactor.OutputStatementInfo[]
---@param output_location 'above'|'below'
---@param reference_range vim.Range
---@param reference_pos vim.Pos
---@return vim.Range?, 'start'|'end'?
function M.get_statement_output_range(buf, output_statements, output_location, reference_range, reference_pos)
  ---@type refactor.OutputStatementInfo|nil
  local statement_for_range = iter(output_statements)
    :filter(
      ---@param os refactor.OutputStatementInfo
      function(os)
        local os_range = range(buf, os.output_statement:range())
        return os_range:has(reference_pos)
      end
    )
    :fold(
      nil,
      ---@param acc nil|refactor.OutputStatementInfo
      ---@param os refactor.OutputStatementInfo
      function(acc, os)
        if not acc then return os end
        if os.output_statement:byte_length() < acc.output_statement:byte_length() then return os end
        return acc
      end
    )
  if not statement_for_range then
    return vim.notify(
      "Couldn't find statement for extracted range using Treesitter",
      vim.log.levels.ERROR,
      { title = "refactoring.nvim" }
    )
  end

  local o_srow, o_scol, o_erow, o_ecol = statement_for_range.output_statement:range()
  local before_range = range(buf, o_srow, o_scol, o_srow, o_scol)
  local after_range = range(buf, o_erow, o_ecol, o_erow, o_ecol)
  local output_range ---@type vim.Range
  local inserted_at ---@type 'start'|'end'
  if statement_for_range.inside and output_location == "above" then
    local inside_range = range(buf, statement_for_range.inside:range())

    if reference_range > inside_range then
      local _, _, inside_erow, inside_ecol = inside_range:to_extmark()
      output_range = range.extmark(buf, inside_erow, inside_ecol, inside_erow, inside_ecol)
      inserted_at = "end"
    else
      output_range = before_range
      inserted_at = "start"
    end
  elseif statement_for_range.inside and output_location == "below" then
    local inside_range = range(buf, statement_for_range.inside:range())

    if reference_range < inside_range then
      local inside_srow, inside_scol = inside_range:to_extmark()
      output_range = range.extmark(buf, inside_srow, inside_scol, inside_srow, inside_scol)
      inserted_at = "start"
    else
      output_range = after_range
      inserted_at = "end"
    end
  else
    if output_location == "above" then
      output_range = before_range
      inserted_at = "start"
    elseif output_location == "below" then
      output_range = after_range
      inserted_at = "end"
    end
  end

  local has_indent_before, space_start = get_has_indent_before(output_range, buf)
  if output_location == "above" and has_indent_before then output_range.start_col = space_start - 1 end

  return output_range, inserted_at
end

---@param output_range vim.Range
---@param buf integer
---@param output_location 'above'|'below'
---@return boolean
function M.get_is_in_midline(output_range, buf, output_location)
  local s_srow = output_range:to_extmark()
  local output_line = api.nvim_buf_get_lines(buf, s_srow, s_srow + 1, true)[1]
  local is_in_mid_line = false
  if output_location == "below" then is_in_mid_line = output_line:find("[^%s]+", output_range.end_col + 1) ~= nil end
  if output_location == "above" then
    local s = output_line:find "[^%s]+"
    is_in_mid_line = s and s < output_range.start_col or false
  end

  return is_in_mid_line
end

return M
