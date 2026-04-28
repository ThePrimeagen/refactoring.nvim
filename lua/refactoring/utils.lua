local api = vim.api
local async = require "async"
local range = require "refactoring.range"
local pos = require "refactoring.pos"
local lsp = vim.lsp
local iter = vim.iter
local ts = vim.treesitter

local M = {}

---@class refactor.TextEdit
---@field range vim.Range
---@field lines string[]

---@param text_edits_by_buf {[integer]: refactor.TextEdit[]}
function M.apply_text_edits(text_edits_by_buf)
  for buf, text_edits in pairs(text_edits_by_buf) do
    table.sort(text_edits, function(a, b)
      return a.range > b.range
    end)

    for _, text_edit in ipairs(text_edits) do
      local srow, scol, erow, ecol = text_edit.range:to_extmark()
      api.nvim_buf_set_text(buf, srow, scol, erow, ecol, text_edit.lines)
    end
  end
end

---@type async fun(opts: table): string
M.input = async.wrap(2, function(opts, cb)
  vim.ui.input(opts, cb)
end)

---@type async fun(items: any[], opts: table)
M.select = async.wrap(3, function(items, opts, on_choice)
  vim.ui.select(items, opts, on_choice)
end)

---@param missing_code_gen string
---@param lang string
function M.code_gen_error(missing_code_gen, lang)
  vim.notify(
    ("There's no `%s` code generation defined for language %s"):format(missing_code_gen, lang),
    vim.log.levels.ERROR,
    { title = "refactoring.nvim" }
  )
end

---@param missing_query string
---@param lang string
function M.query_error(missing_query, lang)
  vim.notify(
    ("There is no `%s` query file for language %s"):format(missing_query, lang),
    vim.log.levels.ERROR,
    { title = "refactoring.nvim" }
  )
end

-- NOTE: the indent logic in `vim.text.indent` counts each char as 1 indent
-- level. the indent logic in `vim.fn.indent` takes into account `expandtab`,
-- `tabstop` and `shiftwidth`.
---@param expandtab boolean
---@param size integer
---@param text string
---@param opts {expandtab: number}?
function M.indent(expandtab, size, text, opts)
  local indented, previous_size = vim.text.indent(size, text, opts)

  if not expandtab then
    indented = indented:gsub("^( +)", function(spaces)
      return ("\t"):rep(#spaces)
    end)
    indented = indented:gsub("\n( +)", function(spaces)
      return "\n" .. ("\t"):rep(#spaces)
    end)
  end
  return indented, previous_size
end

---@class refactor.QfItem
---@field filename string
---@field lnum integer
---@field end_lnum integer
---@field col integer
---@field end_col integer
---@field text string
---@field kind string?

-- TODO: cache if inside of preview. The cache key must include the buffer and
-- cursor location. Actually, the cursor position may change because of the
-- preview, so I don't think I can do that. I may have to have a single,
-- global, cache and invalidate it as soon as possible
--
-- How to invalidate the cache?
-- - it can't be invalidated when no longer in preview, because preview may be canceled
-- - it could be invalidated in a one time autocmd. What event should I use? CursorMove, CursorMoveI and ModeChange?
---@type async fun(): refactor.QfItem[]
M.get_definitions = async.wrap(1, function(cb)
  lsp.buf.definition {
    on_list = function(args)
      cb(args.items)
    end,
  }
end)

---@type async fun(): refactor.QfItem[]
M.get_references = async.wrap(1, function(cb)
  lsp.buf.references({
    includeDeclaration = false,
  }, {
    on_list = function(args)
      cb(args.items)
    end,
  })
end)

-- TODO: maybe move all scope/reference related functions into a diferent file

---@param buf integer
---@param scopes_info refactor.ScopeInfo[]
---@param inner_range vim.Range
---@return refactor.ScopeInfo|nil
local function smaller_containing_scope(buf, scopes_info, inner_range)
  ---@type {si: refactor.ScopeInfo, s: TSNode}|nil
  local declaration_scope = iter(scopes_info)
    :map(
      ---@param si refactor.ScopeInfo
      function(si)
        ---@type TSNode|nil
        local scope = iter(si.scope):find(
          ---@param s TSNode
          function(s)
            local srow, scol, erow, ecol = s:range()
            local scope_range = range(srow, scol, erow, ecol, { buf = buf })
            return scope_range:has(inner_range)
          end
        )
        return si, scope
      end
    )
    :filter(
      ---@param s TSNode|nil
      function(_, s)
        return s ~= nil
      end
    )
    :fold(
      nil,
      ---@param acc nil|{si: refactor.ScopeInfo, s: TSNode}
      ---@param si refactor.ScopeInfo
      ---@param s TSNode
      function(acc, si, s)
        if not acc then return { si = si, s = s } end
        if s:byte_length() < acc.s:byte_length() then return { si = si, s = s } end
        return acc
      end
    )
  if not declaration_scope then return end

  return declaration_scope.si
end

---@alias refactor.declarations_by_scope {[refactor.ScopeInfo]: {[string]: refactor.ReferenceInfo[]}}

---@param references refactor.ReferenceInfo[]
---@param scopes_info refactor.ScopeInfo[]
---@param buf integer
---@return refactor.declarations_by_scope
function M.get_declarations_by_scope(references, scopes_info, buf)
  local declarations_by_scope = iter(references)
    :filter(
      ---@param r refactor.ReferenceInfo
      function(r)
        return r.declaration
      end
    )
    :fold(
      {},
      ---@param acc refactor.declarations_by_scope
      ---@param d refactor.ReferenceInfo
      function(acc, d)
        local srow, scol, erow, ecol = d.identifier:range()
        local d_range = range(srow, scol, erow, ecol, { buf = buf })
        local scope_info = smaller_containing_scope(buf, scopes_info, d_range)
        local identifier = ts.get_node_text(d.identifier, buf)
        assert(scope_info)
        acc[scope_info] = acc[scope_info] or {}
        acc[scope_info][identifier] = acc[scope_info][identifier] or {}
        table.insert(acc[scope_info][identifier], d)

        return acc
      end
    )

  return declarations_by_scope
end

---@param declarations_by_scope refactor.declarations_by_scope
---@param all_scopes refactor.ScopeInfo[]
---@param reference refactor.ReferenceInfo
---@param buf integer
---@return refactor.ScopeInfo|nil
function M.get_declaration_scope(declarations_by_scope, all_scopes, reference, buf)
  local srow, scol, erow, ecol = reference.identifier:range()
  local reference_range = range(srow, scol, erow, ecol, { buf = buf })
  local scopes_for_reference = M.scopes_for_range(buf, all_scopes, reference_range)
  table.sort(scopes_for_reference, function(a, b)
    local a_row, a_col, a_bytes = a.scope[1]:start()
    local b_row, b_col, b_bytes = b.scope[1]:start()
    if a_row ~= b_row then return a_row > b_row end

    return (a_col > b_col or a_col + a_bytes > b_col + b_bytes)
  end)

  local identifier = ts.get_node_text(reference.identifier, buf)
  local reference_start = pos(srow, scol, { buf = buf })
  return iter(scopes_for_reference):find(
    ---@param si refactor.ScopeInfo
    function(si)
      local scope_declarations = declarations_by_scope[si]
      if not scope_declarations then return end
      local identifier_declarations = scope_declarations[identifier]
      if not identifier_declarations then return end

      return iter(identifier_declarations)
        :filter(
          ---@param d refactor.ReferenceInfo
          function(d)
            local d_srow, d_scol = d.identifier:start()
            local d_start = pos(d_srow, d_scol, { buf = buf })
            return reference_start >= d_start
          end
        )
        :fold(
          nil,
          ---@param acc refactor.ReferenceInfo|nil
          ---@param d refactor.ReferenceInfo
          function(acc, d)
            if not acc then return d end

            local d_srow, d_scol = d.identifier:start()
            local d_start = pos(d_srow, d_scol, { buf = buf })
            local acc_srow, acc_scol = d.identifier:start()
            local acc_start = pos(acc_srow, acc_scol, { buf = buf })

            local is_d_closer = M.is_first_closer(d_start, acc_start, reference_start)
            if is_d_closer then return d end
            return acc
          end
        )
    end
  )
end

---@param first vim.Pos
---@param second vim.Pos
---@param position vim.Pos
---@return boolean
function M.is_first_closer(first, second, position)
  local first_row_distance = math.abs(first.row - position.row)
  local second_row_distance = math.abs(second.row - position.row)
  if second_row_distance < first_row_distance then return false end

  local first_col_distance = math.abs(first.col - position.col)
  local second_col_distance = math.abs(second.col - position.col)
  if second_row_distance == first_row_distance and second_col_distance < first_col_distance then return false end
  return true
end

---@param buf integer
---@param all_scopes refactor.ScopeInfo[]
---@param reference_range vim.Range
---@return refactor.ScopeInfo[]
function M.scopes_for_range(buf, all_scopes, reference_range)
  local reference_start = pos(reference_range.start_row, reference_range.start_col, { buf = buf })
  local reference_end = pos(reference_range.end_row, reference_range.end_col, { buf = buf })
  return iter(all_scopes)
    :filter(
      ---@param si refactor.ScopeInfo
      function(si)
        return iter(si.scope):any(
          ---@param s TSNode
          function(s)
            local srow, scol, erow, ecol = s:range()
            local scope_range = range(srow, scol, erow, ecol, { buf = buf })
            return scope_range:has(reference_start)
              or scope_range:has(reference_end)
              or reference_range:has(scope_range)
          end
        )
      end
    )
    :totable()
end

---@param buf integer
---@param range_type 'v' | 'V' | ''
---@return vim.Range
function M.get_selected_range(buf, range_type)
  local range_start = api.nvim_buf_get_mark(buf, "[")
  range_start[1] = range_start[1] - 1
  local range_end = api.nvim_buf_get_mark(buf, "]")
  range_end[1] = range_end[1] - 1
  range_end[2] = range_end[2] + 1
  if range_type == "V" then
    range_start[2] = 0
    range_end[2] = #api.nvim_buf_get_lines(buf, range_end[1], range_end[1] + 1, true)[1]
  end

  return range(range_start[1], range_start[2], range_end[1], range_end[2], { buf = buf })
end

---@class refactor.TsInfo
---@field functions_info refactor.FunctionCallInfo[]
---@field function_calls_info refactor.FunctionInfo[]
---@field returns_info refactor.ReturnInfo[]

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.DebugPathSegmentInfo[]
function M.get_debug_path_segments_info(buf, nested_lang_tree, query)
  ---@type refactor.DebugPathSegmentInfo[]
  local debug_path_segments_info = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match, metadata in query:iter_matches(tree:root(), buf) do
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]
        if name == "debug_path_segment" then
          for i, node in ipairs(nodes) do
            local text = type(metadata.text) == "string" and metadata.text
              or ts.get_node_text(match[metadata.text][i], buf)
            table.insert(debug_path_segments_info, { debug_path_segment = node, text = text })
          end
        end
      end
    end
  end

  return debug_path_segments_info
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.OutputStatementInfo[]
function M.get_output_statements_info(buf, nested_lang_tree, query)
  ---@type refactor.OutputStatementInfo[]
  local output_statements_info = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match, metadata in query:iter_matches(tree:root(), buf) do
      local output_statement ---@type nil|refactor.OutputStatementInfo
      if metadata then
        output_statement = output_statement or {}
        output_statement.inside_only = metadata.inside_only
      end
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "output_statement" then
          output_statement = output_statement or {}
          output_statement.output_statement = nodes[1]
        elseif name == "output_statement.inside" then
          output_statement = output_statement or {}
          output_statement.inside = nodes[1]
        end
      end

      if output_statement then table.insert(output_statements_info, output_statement) end
    end
  end

  return output_statements_info
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.ReferenceInfo[]
function M.get_references_info(buf, nested_lang_tree, query)
  ---@type refactor.ReferenceInfo[]
  local references_info = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match, metadata in query:iter_matches(tree:root(), buf) do
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "reference.identifier" then
          for i, node in ipairs(nodes) do
            table.insert(references_info, {
              identifier = node,
              reference_type = metadata.reference_type,
              type = metadata.types and metadata.types[i],
              declaration = metadata.declaration,
              field = metadata.field,
              function_call_identifier = metadata.function_call_identifier,
            })
          end
        end
      end
    end
  end

  return references_info
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.ScopeInfo[]
function M.get_scopes_info(buf, nested_lang_tree, query)
  ---@type refactor.ScopeInfo[]
  local scopes_info = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match in query:iter_matches(tree:root(), buf) do
      local scope_info ---@type refactor.ScopeInfo|nil
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "scope" then
          scope_info = scope_info or {}
          scope_info.scope = nodes
        elseif name == "scope.inside" then
          scope_info = scope_info or {}
          scope_info.inside = nodes[1]
        end
      end
      if scope_info then table.insert(scopes_info, scope_info) end
    end
  end

  return scopes_info
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return TSNode[]
function M.get_comments(buf, nested_lang_tree, query)
  ---@type TSNode[]
  local comments = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match in query:iter_matches(tree:root(), buf) do
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "comment" then table.insert(comments, nodes[1]) end
      end
    end
  end

  return comments
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.OutputFunctionInfo[]
function M.get_output_functions_info(buf, nested_lang_tree, query)
  ---@type refactor.OutputFunctionInfo[]
  local output_functions_info = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match in query:iter_matches(tree:root(), buf) do
      local output_function ---@type refactor.OutputFunctionInfo|nil
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "output_function.comment" then
          output_function = output_function or {}
          output_function.comment = nodes
        elseif name == "output_function" then
          output_function = output_function or {}
          output_function.fn = nodes[1]
        end
      end
      if output_function then table.insert(output_functions_info, output_function) end
    end
  end

  return output_functions_info
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.InputFunctionInfo[]
function M.get_input_functions_info(buf, nested_lang_tree, query)
  ---@type refactor.InputFunctionInfo[]
  local input_functions_info = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match, metadata in query:iter_matches(tree:root(), buf) do
      local input_function ---@type refactor.InputFunctionInfo|nil
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "input_function" then
          input_function = input_function or {}
          input_function.fn = nodes[1]
          input_function.method = metadata.method
          input_function.singleton = metadata.singleton

          local struct_name = metadata.struct_name
          if struct_name then input_function.struct_name = ts.get_node_text(match[struct_name][1], buf) end
          local struct_var_name = metadata.struct_var_name
          if struct_var_name then input_function.struct_var_name = ts.get_node_text(match[struct_var_name][1], buf) end
        end
      end
      if input_function then table.insert(input_functions_info, input_function) end
    end
  end

  return input_functions_info
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.VariableInfo[]
function M.get_variables_info(buf, nested_lang_tree, query)
  ---@type refactor.VariableInfo[]
  local variables_info = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match in query:iter_matches(tree:root(), buf) do
      local variable_info ---@type refactor.VariableInfo|nil
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "variable.identifier" then
          variable_info = variable_info or {}
          variable_info.identifier = nodes
        elseif name == "variable.identifier_separator" then
          variable_info = variable_info or {}
          variable_info.identifier_separator = nodes
        elseif name == "variable.value_separator" then
          variable_info = variable_info or {}
          variable_info.value_separator = nodes
        elseif name == "variable.value" then
          variable_info = variable_info or {}
          variable_info.value = nodes
        elseif name == "variable.declaration" then
          variable_info = variable_info or {}
          variable_info.declaration = nodes
        end
      end
      if variable_info then table.insert(variables_info, variable_info) end
    end
  end

  return variables_info
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.FunctionInfo[]
---@return refactor.ReturnInfo[]
function M.get_functions_info(buf, nested_lang_tree, query)
  ---@type refactor.FunctionInfo[]
  local functions_info = {}
  ---@type refactor.ReturnInfo[]
  local returns_info = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match in query:iter_matches(tree:root(), buf) do
      local function_info ---@type nil|refactor.FunctionInfo
      local return_info ---@type nil|refactor.ReturnInfo
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "function" then
          function_info = function_info or {}
          function_info["function"] = nodes[1]
        elseif name == "function.outside" then
          function_info = function_info or {}
          function_info.outside = nodes[1]
        elseif name == "function.body" then
          function_info = function_info or {}
          function_info.body = nodes
        elseif name == "function.comment" then
          function_info = function_info or {}
          function_info.comments = nodes
        elseif name == "function.arg" then
          function_info = function_info or {}
          function_info.args = nodes
        end

        if name == "return" then
          return_info = return_info or {}
          return_info["return"] = nodes[1]
        elseif name == "return.value" then
          return_info = return_info or {}
          return_info.values = nodes
        end
      end
      if function_info then table.insert(functions_info, function_info) end
      if return_info then table.insert(returns_info, return_info) end
    end
  end

  return functions_info, returns_info
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.FunctionCallInfo[]
function M.get_function_calls_info(buf, nested_lang_tree, query)
  ---@type refactor.FunctionCallInfo[]
  local function_calls_info = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match in query:iter_matches(tree:root(), buf) do
      local function_call_info ---@type nil|refactor.FunctionCallInfo
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "function_call" then
          function_call_info = function_call_info or {}
          function_call_info.function_call = nodes[1]
        elseif name == "function_call.name" then
          function_call_info = function_call_info or {}
          function_call_info.name = nodes[1]
        elseif name == "function_call.arg" then
          function_call_info = function_call_info or {}
          function_call_info.args = nodes
        elseif name == "function_call.return_value" then
          function_call_info = function_call_info or {}
          function_call_info.return_values = nodes
        elseif name == "function_call.outside" then
          function_call_info = function_call_info or {}
          function_call_info.outside = nodes[1]
        end
      end
      if function_call_info then table.insert(function_calls_info, function_call_info) end
    end
  end

  return function_calls_info
end

---@param buf integer
---@param lang_tree vim.treesitter.LanguageTree
---@param output_range vim.Range
function M.get_debug_path_for_range(buf, lang_tree, output_range)
  local lang = lang_tree:lang()
  local query = ts.query.get(lang, "refactor_debug_path")
  if not query then return M.query_error("refactor_debug_path", lang) end

  local debug_path_segments = M.get_debug_path_segments_info(buf, lang_tree, query)
  ---@type refactor.DebugPathSegmentInfo[]
  local debug_path_segments_for_range = iter(debug_path_segments)
    :filter(
      ---@param dp refactor.DebugPathSegmentInfo
      function(dp)
        local dp_srow, dp_scol, dp_erow, dp_ecol = dp.debug_path_segment:range()
        -- NOTE: in languages without end delimiters (like python) the range of
        -- the `debug_path_segment` won't contain the `output_range`, it'll be
        -- right outside it. So, we add an offset to compensate
        -- TODO: do I need to handle this anywhere else?
        local end_offset = lang == "python" and 1 or 0
        local dp_range = range(dp_srow, dp_scol, dp_erow, dp_ecol + end_offset, { buf = buf })

        return dp_range:has(output_range)
      end
    )
    :totable()

  table.sort(debug_path_segments_for_range, function(a, b)
    local a_srow, a_scol = a.debug_path_segment:range()
    local a_start_pos = pos(a_srow, a_scol, { buf = buf })
    local b_srow, b_scol = b.debug_path_segment:range()
    local b_start_pos = pos(b_srow, b_scol, { buf = buf })
    return a_start_pos < b_start_pos
  end)

  local debug_path_for_range = iter(debug_path_segments_for_range)
    :map(
      ---@param dp refactor.DebugPathSegmentInfo
      function(dp)
        return dp.text
      end
    )
    :join "#"
  return debug_path_for_range
end

return M
