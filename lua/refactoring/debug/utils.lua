local range = require "refactoring.range"
local iter = vim.iter

local M = {}

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

  return output_range, inserted_at
end

return M
