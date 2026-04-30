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

---@param lang string
function M.commentstring_error(lang)
  vim.notify(
    ("Couldn't get the 'commentstring' for language %s"):format(lang),
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

local cached_definitions ---@type vim.quickfix.entry[]|nil
---@type async fun(): vim.quickfix.entry[]
M.get_lsp_definitions = async.wrap(2, function(is_preview, cb)
  if cached_definitions then return cb(cached_definitions) end

  lsp.buf.definition {
    on_list = function(args)
      if is_preview then cached_definitions = args.items end
      api.nvim_create_autocmd("CmdlineLeave", {
        group = api.nvim_create_augroup("refactoring-definitions-cache", { clear = true }),
        once = true,
        callback = function()
          cached_definitions = nil
        end,
      })

      cb(args.items)
    end,
  }
end)

local cached_references ---@type vim.quickfix.entry[]|nil
---@type async fun(): vim.quickfix.entry[]
M.get_lsp_references = async.wrap(2, function(is_preview, cb)
  if cached_references then return cb(cached_references) end

  lsp.buf.references({
    includeDeclaration = false,
  }, {
    on_list = function(args)
      if is_preview then cached_references = args.items end
      api.nvim_create_autocmd("CmdlineLeave", {
        group = api.nvim_create_augroup("refactoring-references-cache", { clear = true }),
        once = true,
        callback = function()
          cached_references = nil
        end,
      })

      cb(args.items)
    end,
  })
end)

-- TODO: maybe move all scope/reference related functions into a diferent file

---@param buf integer
---@param scopes refactor.Scope[]
---@param inner_range vim.Range
---@return refactor.Scope|nil
local function smaller_containing_scope(buf, scopes, inner_range)
  ---@type {si: refactor.Scope, s: TSNode}|nil
  local declaration_scope = iter(scopes)
    :map(
      ---@param si refactor.Scope
      function(si)
        ---@type TSNode|nil
        local scope = iter(si.scope):find(
          ---@param s TSNode
          function(s)
            local scope_range = range(buf, s:range())
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
      ---@param acc nil|{si: refactor.Scope, s: TSNode}
      ---@param si refactor.Scope
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

---@alias refactor.declarations_by_scope {[refactor.Scope]: {[string]: refactor.Reference[]}}

---@param references refactor.Reference[]
---@param scopes refactor.Scope[]
---@param buf integer
---@return refactor.declarations_by_scope
function M.get_declarations_by_scope(references, scopes, buf)
  local declarations_by_scope = iter(references)
    :filter(
      ---@param r refactor.Reference
      function(r)
        return r.declaration
      end
    )
    :fold(
      {},
      ---@param acc refactor.declarations_by_scope
      ---@param d refactor.Reference
      function(acc, d)
        local d_range = range(buf, d.identifier:range())
        local scope = smaller_containing_scope(buf, scopes, d_range)
        local identifier = ts.get_node_text(d.identifier, buf)
        assert(scope)
        acc[scope] = acc[scope] or {}
        acc[scope][identifier] = acc[scope][identifier] or {}
        table.insert(acc[scope][identifier], d)

        return acc
      end
    )

  return declarations_by_scope
end

---@param declarations_by_scope refactor.declarations_by_scope
---@param all_scopes refactor.Scope[]
---@param reference refactor.Reference
---@param buf integer
---@return refactor.Scope|nil
function M.get_declaration_scope(declarations_by_scope, all_scopes, reference, buf)
  local reference_range = range(buf, reference.identifier:range())
  local scopes_for_reference = M.scopes_for_range(buf, all_scopes, reference_range)
  table.sort(scopes_for_reference, function(a, b)
    local a_row, a_col, a_bytes = a.scope[1]:start()
    local b_row, b_col, b_bytes = b.scope[1]:start()
    if a_row ~= b_row then return a_row > b_row end

    return (a_col > b_col or a_col + a_bytes > b_col + b_bytes)
  end)

  local identifier = ts.get_node_text(reference.identifier, buf)
  local reference_start = pos(buf, reference_range.start_row, reference_range.start_col)
  return iter(scopes_for_reference):find(
    ---@param si refactor.Scope
    function(si)
      local scope_declarations = declarations_by_scope[si]
      if not scope_declarations then return end
      local identifier_declarations = scope_declarations[identifier]
      if not identifier_declarations then return end

      return iter(identifier_declarations)
        :filter(
          ---@param d refactor.Reference
          function(d)
            local d_start = pos(buf, d.identifier:start())
            return reference_start >= d_start
          end
        )
        :fold(
          nil,
          ---@param acc refactor.Reference|nil
          ---@param d refactor.Reference
          function(acc, d)
            if not acc then return d end

            local d_start = pos(buf, d.identifier:start())
            local acc_start = pos(buf, d.identifier:start())

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
---@param all_scopes refactor.Scope[]
---@param reference_range vim.Range
---@return refactor.Scope[]
function M.scopes_for_range(buf, all_scopes, reference_range)
  local reference_start = pos(buf, reference_range.start_row, reference_range.start_col)
  local reference_end = pos(buf, reference_range.end_row, reference_range.end_col)
  return iter(all_scopes)
    :filter(
      ---@param si refactor.Scope
      function(si)
        return iter(si.scope):any(
          ---@param s TSNode
          function(s)
            local scope_range = range(buf, s:range())
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

  return range(buf, range_start[1], range_start[2], range_end[1], range_end[2])
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.DebugPathSegment[]
function M.get_debug_path_segments(buf, nested_lang_tree, query)
  ---@type refactor.DebugPathSegment[]
  local debug_path_segments = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match, metadata in query:iter_matches(tree:root(), buf) do
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]
        if name == "debug_path_segment" then
          for i, node in ipairs(nodes) do
            local text = type(metadata.text) == "string" and metadata.text
              or ts.get_node_text(match[metadata.text][i], buf)
            table.insert(
              debug_path_segments,
              { debug_path_segment = node, text = text, metadata = metadata[capture_id] }
            )
          end
        end
      end
    end
  end

  return debug_path_segments
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.OutputStatement[]
function M.get_output_statements(buf, nested_lang_tree, query)
  ---@type refactor.OutputStatement[]
  local output_statements = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match, metadata in query:iter_matches(tree:root(), buf) do
      local output_statement ---@type nil|refactor.OutputStatement
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

      if output_statement then table.insert(output_statements, output_statement) end
    end
  end

  return output_statements
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.Reference[]
function M.get_references(buf, nested_lang_tree, query)
  ---@type refactor.Reference[]
  local references = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match, metadata in query:iter_matches(tree:root(), buf) do
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "reference.identifier" then
          for i, node in ipairs(nodes) do
            table.insert(references, {
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

  return references
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.Scope[]
function M.get_scopes(buf, nested_lang_tree, query)
  ---@type refactor.Scope[]
  local scopes = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match in query:iter_matches(tree:root(), buf) do
      local scope ---@type refactor.Scope|nil
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "scope" then
          scope = scope or {}
          scope.scope = nodes
        elseif name == "scope.inside" then
          scope = scope or {}
          scope.inside = nodes[1]
        end
      end
      if scope then table.insert(scopes, scope) end
    end
  end

  return scopes
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
---@return refactor.OutputFunction[]
function M.get_output_functions(buf, nested_lang_tree, query)
  ---@type refactor.OutputFunction[]
  local output_functions = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match in query:iter_matches(tree:root(), buf) do
      local output_function ---@type refactor.OutputFunction|nil
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
      if output_function then table.insert(output_functions, output_function) end
    end
  end

  return output_functions
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.InputFunction[]
function M.get_input_functions(buf, nested_lang_tree, query)
  ---@type refactor.InputFunction[]
  local input_functions = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match, metadata in query:iter_matches(tree:root(), buf) do
      local input_function ---@type refactor.InputFunction|nil
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
      if input_function then table.insert(input_functions, input_function) end
    end
  end

  return input_functions
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.Variable[]
function M.get_variables(buf, nested_lang_tree, query)
  ---@type refactor.Variable[]
  local variables = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match in query:iter_matches(tree:root(), buf) do
      local variable ---@type refactor.Variable|nil
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "variable.identifier" then
          variable = variable or {}
          variable.identifier = nodes
        elseif name == "variable.identifier_separator" then
          variable = variable or {}
          variable.identifier_separator = nodes
        elseif name == "variable.value_separator" then
          variable = variable or {}
          variable.value_separator = nodes
        elseif name == "variable.value" then
          variable = variable or {}
          variable.value = nodes
        elseif name == "variable.declaration" then
          variable = variable or {}
          variable.declaration = nodes
        end
      end
      if variable then table.insert(variables, variable) end
    end
  end

  return variables
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.Function[]
---@return refactor.Return[]
function M.get_functions(buf, nested_lang_tree, query)
  ---@type refactor.Function[]
  local functions = {}
  ---@type refactor.Return[]
  local returns = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match in query:iter_matches(tree:root(), buf) do
      local function_ ---@type nil|refactor.Function
      local return_ ---@type nil|refactor.Return
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "function" then
          function_ = function_ or {}
          function_["function"] = nodes[1]
        elseif name == "function.outside" then
          function_ = function_ or {}
          function_.outside = nodes[1]
        elseif name == "function.body" then
          function_ = function_ or {}
          function_.body = nodes
        elseif name == "function.comment" then
          function_ = function_ or {}
          function_.comments = nodes
        elseif name == "function.arg" then
          function_ = function_ or {}
          function_.args = nodes
        end

        if name == "return" then
          return_ = return_ or {}
          return_["return"] = nodes[1]
        elseif name == "return.value" then
          return_ = return_ or {}
          return_.values = nodes
        end
      end
      if function_ then table.insert(functions, function_) end
      if return_ then table.insert(returns, return_) end
    end
  end

  return functions, returns
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param query vim.treesitter.Query
---@return refactor.FunctionCall[]
function M.get_function_calls(buf, nested_lang_tree, query)
  ---@type refactor.FunctionCall[]
  local function_calls = {}

  for _, tree in ipairs(nested_lang_tree:trees()) do
    for _, match in query:iter_matches(tree:root(), buf) do
      local function_call ---@type nil|refactor.FunctionCall
      for capture_id, nodes in pairs(match) do
        local name = query.captures[capture_id]

        if name == "function_call" then
          function_call = function_call or {}
          function_call.function_call = nodes[1]
        elseif name == "function_call.name" then
          function_call = function_call or {}
          function_call.name = nodes[1]
        elseif name == "function_call.arg" then
          function_call = function_call or {}
          function_call.args = nodes
        elseif name == "function_call.return_value" then
          function_call = function_call or {}
          function_call.return_values = nodes
        elseif name == "function_call.outside" then
          function_call = function_call or {}
          function_call.outside = nodes[1]
        end
      end
      if function_call then table.insert(function_calls, function_call) end
    end
  end

  return function_calls
end

---@param buf integer
---@param lang_tree vim.treesitter.LanguageTree
---@param output_range vim.Range
function M.get_debug_path_for_range(buf, lang_tree, output_range)
  local lang = lang_tree:lang()
  local query = ts.query.get(lang, "refactor_debug_path")
  if not query then return M.query_error("refactor_debug_path", lang) end

  local debug_path_segments = M.get_debug_path_segments(buf, lang_tree, query)
  ---@type refactor.DebugPathSegment[]
  local debug_path_segments_for_range = iter(debug_path_segments)
    :filter(
      ---@param dp refactor.DebugPathSegment
      function(dp)
        ---@type integer, integer, integer, integer, integer
        local dp_srow, dp_scol, _, dp_erow, dp_ecol = unpack(ts.get_range(dp.debug_path_segment, buf, dp.metadata))
        local dp_range = range(buf, dp_srow, dp_scol, dp_erow, dp_ecol)

        return dp_range:has(output_range)
      end
    )
    :totable()

  table.sort(debug_path_segments_for_range, function(a, b)
    local a_start_pos = pos(buf, a.debug_path_segment:range())
    local b_start_pos = pos(buf, b.debug_path_segment:range())
    return a_start_pos < b_start_pos
  end)

  local debug_path_for_range = iter(debug_path_segments_for_range)
    :map(
      ---@param dp refactor.DebugPathSegment
      function(dp)
        return dp.text
      end
    )
    :join "#"
  return debug_path_for_range
end

return M
