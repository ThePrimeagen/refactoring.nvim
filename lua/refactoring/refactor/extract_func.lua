local async = require "async"
local pos = require "refactoring.pos"
local range = require "refactoring.range"
local iter = vim.iter
local ts = vim.treesitter
local api = vim.api

local M = {}

---@class refactor.extract_func.code_generation.function_declaration.Opts
---@field args refactor.Variable[]
---@field name string
---@field body string
---@field return_values refactor.Variable[]
---@field method boolean?
---@field singleton boolean?
---@field struct_var_name string?
---@field struct_name string?

---@class refactor.extract_func.code_generation.function_call.Opts
---@field args string[]
---@field name string
---@field return_values refactor.Variable[]
---@field method boolean?
---@field struct_var_name string?

---@class refactor.extract_func.code_generation.return_statement.Opts
---@field return_values refactor.Variable[]

---@class refactor.extract_func.CodeGeneration
---@field function_declaration {[string]: nil|fun(opts: refactor.extract_func.code_generation.function_declaration.Opts): string}
---@field function_call {[string]: nil|fun(opts: refactor.extract_func.code_generation.function_call.Opts): string}
---@field return_statement {[string]: nil|fun(opts: refactor.extract_func.code_generation.return_statement.Opts): string}

---@class refactor.extract_func.UserCodeGeneration
---@field function_declaration? {[string]: nil|fun(opts: refactor.extract_func.code_generation.function_declaration.Opts): string}
---@field function_call? {[string]: nil|fun(opts: refactor.extract_func.code_generation.function_call.Opts): string}
---@field return_statement? {[string]: nil|fun(opts: refactor.extract_func.code_generation.return_statement.Opts): string}

---@class refactor.OutputFunctionInfo
---@field comment TSNode[]?
---@field fn TSNode

---@class refactor.InputFunctionInfo
---@field fn TSNode
---@field method boolean?
---@field singleton boolean?
---@field struct_name string?
---@field struct_var_name string?

---@param o refactor.OutputFunctionInfo
---@return TSNode
local function choose_output(o)
  return o.comment and o.comment[1] or o.fn
end

---@param in_buf integer
---@param out_buf integer
---@param lang string
---@param selected_range vim.Range
---@return TSNode?
local function get_output_node(in_buf, out_buf, lang, selected_range)
  local is_first_closer = require("refactoring.utils").is_first_closer
  local query_error = require("refactoring.utils").query_error
  local get_output_functions_info = require("refactoring.utils").get_output_functions_info

  local lang_tree, err1 = ts.get_parser(out_buf, nil, { error = false })
  if not lang_tree then
    ---@cast err1 -nil
    vim.notify(err1, vim.log.levels.ERROR, { title = "refactoring.nvim" })
    return
  end
  if in_buf ~= out_buf then
    -- TODO: use async parsing
    lang_tree:parse(true)
  end

  local nested_lang_tree ---@type vim.treesitter.LanguageTree?
  if in_buf == out_buf then
    local selected_range_ts =
      { selected_range.start_row, selected_range.start_col, selected_range.end_row, selected_range.end_col }
    nested_lang_tree = lang_tree:language_for_range(selected_range_ts)
  elseif lang_tree:lang() == lang then
    nested_lang_tree = lang_tree
  else
    nested_lang_tree = iter(lang_tree:children()):find(
      ---@param l string
      function(l)
        return l == lang
      end
    )
  end
  if not nested_lang_tree then return end

  local output_function_query = ts.query.get(lang, "refactor_output_function")
  if not output_function_query then return query_error("refactor_output_function", lang) end

  local outputs = get_output_functions_info(out_buf, nested_lang_tree, output_function_query)

  if in_buf ~= out_buf and outputs[#outputs] then return choose_output(outputs[#outputs]) end
  if in_buf ~= out_buf then return end

  local selected_start_pos = pos(selected_range.buf, selected_range.start_row, selected_range.start_col)
  ---@type refactor.OutputFunctionInfo|nil
  local selected_output = iter(outputs)
    :filter(
      ---@param o refactor.OutputFunctionInfo
      function(o)
        local n = choose_output(o)
        local n_start = pos(out_buf, n:start())
        return n_start < selected_start_pos
      end
    )
    :fold(
      nil,
      ---@param acc refactor.OutputFunctionInfo|nil
      ---@param o refactor.OutputFunctionInfo
      function(acc, o)
        if not acc then return o end

        local n = choose_output(o)
        local o_start = pos(out_buf, n:start())
        local acc_n = choose_output(acc)
        local acc_start = pos(out_buf, acc_n:start())

        local is_o_closer = is_first_closer(o_start, acc_start, selected_start_pos)
        if is_o_closer then return o end
        return acc
      end
    )

  if not selected_output then return end

  return choose_output(selected_output)
end

---@param buf integer
---@param nested_lang_tree vim.treesitter.LanguageTree
---@param selected_range vim.Range
---@return refactor.InputFunctionInfo?
local function get_input_info(buf, nested_lang_tree, selected_range)
  local query_error = require("refactoring.utils").query_error
  local get_input_functions_info = require("refactoring.utils").get_input_functions_info
  local is_first_closer = require("refactoring.utils").is_first_closer

  local lang = nested_lang_tree:lang()
  local output_function_query = ts.query.get(lang, "refactor_input_function")
  if not output_function_query then return query_error("refactor_input_function", lang) end

  local inputs = get_input_functions_info(buf, nested_lang_tree, output_function_query)

  ---@type refactor.InputFunctionInfo|nil
  local surrounding_input = iter(inputs)
    :filter(
      ---@param i refactor.InputFunctionInfo
      function(i)
        local n_range = range(buf, i.fn:range())
        return n_range:has(selected_range)
      end
    )
    :fold(
      nil,
      ---@param acc refactor.InputFunctionInfo|nil
      ---@param i refactor.InputFunctionInfo
      function(acc, i)
        if not acc then return i end

        if i.fn:byte_length() < acc.fn:byte_length() then return i end
        return acc
      end
    )

  if surrounding_input then return surrounding_input end

  local selected_start_pos = pos(selected_range.buf, selected_range.start_row, selected_range.start_col)
  ---@type refactor.InputFunctionInfo|nil
  local previous_input = iter(inputs)
    :filter(
      ---@param i refactor.InputFunctionInfo
      function(i)
        local n_start = pos(buf, i.fn:start())
        return n_start < selected_start_pos
      end
    )
    :fold(
      nil,
      ---@param acc refactor.InputFunctionInfo|nil
      ---@param i refactor.InputFunctionInfo
      function(acc, i)
        if not acc then return i end

        local i_start = pos(buf, i.fn:start())
        local acc_start = pos(buf, acc.fn:start())

        local is_i_closer = is_first_closer(i_start, acc_start, selected_start_pos)
        if is_i_closer then return i end
        return acc
      end
    )
  if not previous_input then return end

  -- We discard this because these information is only correct if input found is surrounding `selected_range`
  previous_input.method = nil
  previous_input.singleton = nil
  previous_input.struct_name = nil
  previous_input.struct_var_name = nil
  return previous_input
end

---@class refactor.ReferenceInfo
---@field identifier TSNode
---@field type string|{identifier: string}|vim.NIL|nil
---@field reference_type 'read'|'write'
---@field declaration boolean
---@field field boolean
---@field function_call_identifier boolean

---@class refactor.Variable
---@field identifier string
---@field type string|nil

---@class refactor.extract_func.Opts
---@field selected_range vim.Range
---@field in_buf integer
---@field lines string[]
---@field out_buf integer
---@field fn_name string
---@field config refactor.Config

---@param opts refactor.extract_func.Opts
local function extract_func(opts)
  local apply_text_edits = require("refactoring.utils").apply_text_edits
  local code_gen_error = require("refactoring.utils").code_gen_error
  local indent = require("refactoring.utils").indent
  local get_declarations_by_scope = require("refactoring.utils").get_declarations_by_scope
  local scopes_for_range = require("refactoring.utils").scopes_for_range
  local get_declaration_scope = require("refactoring.utils").get_declaration_scope
  local get_references_info = require("refactoring.utils").get_references_info
  local get_scopes_info = require("refactoring.utils").get_scopes_info
  local query_error = require("refactoring.utils").query_error

  local code_generation = opts.config.refactor.extract_func.code_generation

  local selected_range = opts.selected_range
  local in_buf = opts.in_buf
  local lines = opts.lines
  local out_buf = opts.out_buf
  local fn_name = opts.fn_name

  local lang_tree, err1 = ts.get_parser(in_buf, nil, { error = false })
  if not lang_tree then
    ---@cast err1 -nil
    vim.notify(err1, vim.log.levels.ERROR, { title = "refactoring.nvim" })
    return
  end
  -- TODO: use async parsing
  lang_tree:parse(true)
  local selected_range_ts =
    { selected_range.start_row, selected_range.start_col, selected_range.end_row, selected_range.end_col }
  local nested_lang_tree = lang_tree:language_for_range(selected_range_ts)
  local lang = nested_lang_tree:lang()
  local reference_query = ts.query.get(lang, "refactor_reference")
  if not reference_query then return query_error("refactor_reference", lang) end
  local scope_query = ts.query.get(lang, "refactor_scope")
  if not scope_query then return query_error("refactor_scope", lang) end

  local input_info = get_input_info(in_buf, nested_lang_tree, selected_range)
  -- TODO: maybe use a different type? `input_info.fn` is no needed after `get_input_info`
  if not input_info then input_info = {} end
  local output_node = get_output_node(in_buf, out_buf, lang, selected_range)

  local output_range ---@type vim.Range
  if output_node then
    local output_start = pos(in_buf, output_node:start())
    local row, col = output_start:to_extmark()
    output_range = range.extmark(out_buf, row, col, row, col)
  elseif in_buf == out_buf then
    -- TODO: Is this a good default possition when in_buf == out_buf? Which could be a better one?
    output_range = range(
      selected_range.buf,
      selected_range.start_row,
      selected_range.start_col,
      selected_range.start_row,
      selected_range.start_col
    )
  else
    -- TODO: Is this a good default possition when in_buf ~= out_buf? Which could be a better one?
    output_range = range.extmark(out_buf, 0, 0, 0, 0)
  end

  local references_info = get_references_info(in_buf, nested_lang_tree, reference_query)
  local scopes_info = get_scopes_info(in_buf, nested_lang_tree, scope_query)

  local scopes_for_selected_range = scopes_for_range(in_buf, scopes_info, selected_range)

  local declarations_info = iter(references_info)
    :filter(
      ---@param r refactor.ReferenceInfo
      function(r)
        return r.declaration
      end
    )
    :totable()

  local declarations_info_by_scope = get_declarations_by_scope(references_info, scopes_info, in_buf)

  ---@type refactor.ReferenceInfo[]
  local typed_references_info = iter(references_info)
    :filter(
      ---@param r refactor.ReferenceInfo
      function(r)
        return r.type ~= nil and r.type ~= vim.NIL
      end
    )
    :totable()
  table.sort(
    typed_references_info,
    ---@param a refactor.ReferenceInfo
    ---@param b refactor.ReferenceInfo
    function(a, b)
      local a_range = range(in_buf, a.identifier:range())
      local b_range = range(in_buf, b.identifier:range())

      return a_range < b_range
    end
  )
  local selected_end_pos = pos(selected_range.buf, selected_range.end_row, selected_range.end_col)
  ---@type {[refactor.ScopeInfo]: {scope_info: refactor.ScopeInfo, types: {[string]: string|{identifier: string}}}}
  local types_by_scope_up_to_selected_range_end = iter(typed_references_info)
    :filter(
      ---@param r refactor.ReferenceInfo
      function(r)
        -- TODO: maybe extract this filter into some function, there are
        -- similar ones for all the `before_` variables
        local declaration_scope = get_declaration_scope(declarations_info_by_scope, scopes_info, r, in_buf)

        local is_in_scope = false
        if declaration_scope then
          is_in_scope = iter(scopes_for_selected_range):any(
            ---@param si refactor.ScopeInfo
            function(si)
              return si == declaration_scope
            end
          )
        end

        -- TODO: I can probably simplify this
        local srow, scol, erow, ecol = r.identifier:range()
        local node_start_pos = pos(in_buf, srow, scol)
        local node_end_pos = pos(in_buf, erow, ecol)
        return node_start_pos <= selected_end_pos and node_end_pos <= selected_end_pos and is_in_scope
      end
    )
    :fold(
      {},
      ---@param acc {[refactor.ScopeInfo]: {scope_info: refactor.ScopeInfo, types: {[string]: string|{identifier: string}}}}
      ---@param r refactor.ReferenceInfo
      function(acc, r)
        if r.type == nil or r.type == vim.NIL then return acc end

        local scope = get_declaration_scope(declarations_info_by_scope, scopes_info, r, in_buf)
        if not scope then return acc end

        acc[scope] = acc[scope] or {}
        acc[scope].types = acc[scope].types or {}
        local identifier = ts.get_node_text(r.identifier, in_buf)
        acc[scope].types[identifier] = r.type
        acc[scope].scope_info = scope
        return acc
      end
    )

  ---@type {scope_info: refactor.ScopeInfo, types: {[string]: string|{identifier: string}}}[]
  local types_with_scope_up_to_selected_range_end = vim.tbl_values(types_by_scope_up_to_selected_range_end)
  table.sort(types_with_scope_up_to_selected_range_end, function(a, b)
    local a_range = range(in_buf, a.scope_info.scope[1]:range())
    local b_range = range(in_buf, b.scope_info.scope[1]:range())

    return a_range < b_range
  end)
  ---@type {[string]: string|{identifier: string}}[]
  local scoped_types_up_to_selected_range_end = iter(types_with_scope_up_to_selected_range_end)
    :map(
      ---@param a {scope_info: refactor.ScopeInfo, types: {[string]: string|{identifier: string}}}
      function(a)
        return a.types
      end
    )
    :totable()
  -- TODO: check if this should rev or not. In either case, remove it and
  -- change the sorting above. But I'm using oposite sorting orders here and
  -- below, so double check this logic
  iter(scoped_types_up_to_selected_range_end):rev():each(
    ---@param t {[string]: string|{identifier: string}}
    function(t)
      for identifier, identifier_type in pairs(t) do
        if type(identifier_type) == "table" then
          ---@type {[string]: string|{identifier: string}}
          local types = iter(scoped_types_up_to_selected_range_end):find(
            ---@param types {[string]: string|{identifier: string}}
            function(types)
              return types[identifier_type.identifier] ~= nil
            end
          )
          local type = types and types[identifier_type.identifier]
          -- TODO: check for recursive variable references or
          -- something like that?
          t[identifier] = type
        end
      end
    end
  )
  -- TODO: actually, not all types will be string at this point.
  -- Actuallyx2, they will be if I resolve the types in the correct order
  ---@cast scoped_types_up_to_selected_range_end{[string]: string}[]

  ---@type refactor.ReferenceInfo[]
  local references_inside_selected_range = iter(references_info)
    :filter(
      ---@param r refactor.ReferenceInfo
      function(r)
        local n = r.identifier
        local node_range = range(in_buf, n:range())
        return selected_range:has(node_range)
      end
    )
    :totable()

  local reference_to_variable =
    ---@param ri refactor.ReferenceInfo
    function(ri)
      local identifier = ts.get_node_text(ri.identifier, in_buf)

      ---@type {[string]: string}|nil
      local types = iter(scoped_types_up_to_selected_range_end):find(
        ---@param types {[string]: string}
        function(types)
          return types[identifier] ~= nil
        end
      )
      local type = types and types[identifier]
      return {
        identifier = identifier,
        type = type,
      }
    end

  ---@type refactor.Variable[]
  local variables_inside_selected_range = iter(references_inside_selected_range)
    :map(reference_to_variable)
    :unique(
      ---@param v refactor.Variable
      function(v)
        return v.identifier
      end
    )
    :totable()

  local reference_to_text =
    ---@param reference refactor.ReferenceInfo
    function(reference)
      return ts.get_node_text(reference.identifier, in_buf)
    end
  ---@type string[]
  local write_identifiers_inside_selected_range = iter(references_inside_selected_range)
    :filter(
      ---@param r refactor.ReferenceInfo
      function(r)
        return r.reference_type == "write"
      end
    )
    :map(reference_to_text)
    :unique()
    :totable()

  ---@type string[]
  local declarations_inside_selected_range = iter(declarations_info)
    :filter(
      ---@param r refactor.ReferenceInfo
      function(r)
        local r_range = range(in_buf, r.identifier:range())
        return selected_range:has(r_range)
      end
    )
    :map(reference_to_text)
    :totable()

  ---@type string[]
  local declarations_before_output_range = iter(declarations_info)
    :filter(
      ---@param r refactor.ReferenceInfo
      function(r)
        local declaration_scope = get_declaration_scope(declarations_info_by_scope, scopes_info, r, in_buf)

        local is_in_scope = false
        if declaration_scope then
          is_in_scope = iter(scopes_for_selected_range):any(
            ---@param si refactor.ScopeInfo
            function(si)
              return si == declaration_scope
            end
          )
        end

        local node_range = range(in_buf, r.identifier:range())
        return node_range <= output_range and is_in_scope
      end
    )
    :map(reference_to_text)
    :totable()
  ---@type string[]
  local declarations_before_selected_range = iter(declarations_info)
    :filter(
      ---@param r refactor.ReferenceInfo
      function(r)
        local declaration_scope = get_declaration_scope(declarations_info_by_scope, scopes_info, r, in_buf)

        local is_in_scope = false
        if declaration_scope then
          is_in_scope = iter(scopes_for_selected_range):any(
            ---@param si refactor.ScopeInfo
            function(si)
              return si == declaration_scope
            end
          )
        end

        local node_range = range(in_buf, r.identifier:range())
        return node_range <= selected_range and is_in_scope
      end
    )
    :map(reference_to_text)
    :totable()

  ---@type refactor.Variable[]
  local args = iter(variables_inside_selected_range)
    :filter(
      ---@param r refactor.Variable
      function(r)
        -- TODO: not only check if there are declarations inside the extracted
        -- range. Check if the first usage of the identifier is after the end
        -- of the first declaration inside the extracted range
        return not vim.list_contains(declarations_inside_selected_range, r.identifier)
          and not vim.list_contains(declarations_before_output_range, r.identifier)
          and vim.list_contains(declarations_before_selected_range, r.identifier)
      end
    )
    :totable()

  ---@type string[]
  local variables_after_selected_range = iter(references_info)
    :filter(
      ---@param r refactor.ReferenceInfo
      function(r)
        local declaration_scope = get_declaration_scope(declarations_info_by_scope, scopes_info, r, in_buf)

        local is_in_scope = false
        if declaration_scope then
          is_in_scope = iter(scopes_for_selected_range):any(
            ---@param si refactor.ScopeInfo
            function(si)
              return si == declaration_scope
            end
          )
        end

        local node_range = range(in_buf, r.identifier:range())
        return node_range > selected_range and is_in_scope
      end
    )
    :map(reference_to_variable)
    :unique(
      ---@param v refactor.Variable
      function(v)
        return v.identifier
      end
    )
    :totable()
  ---@type refactor.Variable[]
  local return_values = iter(variables_after_selected_range)
    :filter(
      ---@param v refactor.Variable
      function(v)
        return vim.list_contains(write_identifiers_inside_selected_range, v.identifier)
      end
    )
    :totable()

  local expandtab = vim.bo[out_buf].expandtab

  local body = table.concat(lines, "\n")
  local body_indent ---@type integer
  body, body_indent = indent(expandtab, 0, body)
  local get_return_statement = code_generation.return_statement[lang]
  if not get_return_statement then return code_gen_error("return_statement", lang) end
  local get_function_declaration = code_generation.function_declaration[lang]
  if not get_function_declaration then return code_gen_error("function_declaration", lang) end
  local get_function_call = code_generation.function_call[lang]
  if not get_function_call then return code_gen_error("function_call", lang) end
  if #return_values > 0 then
    -- TODO: instead, create two statements: one to declare all variables
    -- declared inside on the body of the function and also returned, a second
    -- one to call the function **without** declaring any of the variables,
    -- only assigning to them
    local return_statement = get_return_statement {
      return_values = return_values,
    }
    body = body .. return_statement
  end
  local indent_width = vim.bo[in_buf].shiftwidth > 0 and vim.bo[in_buf].shiftwidth or vim.bo[in_buf].tabstop
  body = indent(expandtab, expandtab and 1 * indent_width or 1, body)
  local function_declaration = get_function_declaration {
    args = args,
    body = body,
    name = fn_name,
    return_values = return_values,
    method = input_info.method,
    singleton = input_info.singleton,
    struct_name = input_info.struct_name,
    struct_var_name = input_info.struct_var_name,
  } .. "\n\n"
  function_declaration = vim.text.indent((input_info.method and 1 or 0) * indent_width, function_declaration)
  if not expandtab then function_declaration:gsub("^(%s+)", function(spaces)
    return ("\t"):rep(#spaces)
  end) end
  local function_call = get_function_call {
    args = args,
    name = fn_name,
    return_values = return_values,
    method = input_info.method,
    struct_var_name = input_info.struct_var_name,
  }
  function_call = indent(expandtab, body_indent, function_call)

  ---@type {[integer]: refactor.TextEdit[]}
  local text_edits_by_buf = {}
  text_edits_by_buf[in_buf] = {}
  table.insert(text_edits_by_buf[in_buf], { range = selected_range, lines = vim.split(function_call, "\n") })

  local function_definition_lines = vim.split(function_declaration, "\n")
  if input_info.method then
    -- NOTE: treesitter nodes don't include whitespace. So, output region's
    -- first line it's (probably) already indented
    function_definition_lines[1] = indent(expandtab, 0, function_definition_lines[1])

    -- NOTE: `vim.text.indent` doesn't add indent for empty lines, but we are
    -- inserting text before already indented lines, so we'll remove their
    -- indentation if we don't do it manually
    local last_line_indent = expandtab and (" "):rep(indent_width) or "\t"
    local length = #function_definition_lines
    function_definition_lines[length] = function_definition_lines[length] .. last_line_indent
  end
  text_edits_by_buf[out_buf] = text_edits_by_buf[out_buf] or {}
  table.insert(text_edits_by_buf[out_buf], {
    range = output_range,
    lines = function_definition_lines,
  })
  apply_text_edits(text_edits_by_buf)

  if opts.config.show_success_message then
    vim.notify("Function extracted", vim.log.levels.INFO, { title = "refactoring.nvim" })
  end

  -- TODO: maybe use snippets to expand the generated function and navigate
  -- through type placeholders? Although, that won't work for multiple text
  -- edits, snippets work for a single text edit. So, maybe use set the qf list
  -- (optionally) to the locations that should be edited?
end

---@param range_type 'v' | 'V' | ''
---@param config refactor.Config
M.extract_func = function(range_type, config)
  local get_selected_range = require("refactoring.utils").get_selected_range
  local input = require("refactoring.utils").input

  local opts = config.refactor.extract_func

  local buf = api.nvim_get_current_buf()
  local selected_range = get_selected_range(buf, range_type)
  local lines = vim.fn.getregion(vim.fn.getpos "'[", vim.fn.getpos "']", { type = range_type })

  local task = async.run(function()
    local fn_name = opts.input and table.remove(opts.input, 1) or input { prompt = "Function name: " }
    if not fn_name then return end

    extract_func {
      in_buf = buf,
      out_buf = buf,
      selected_range = selected_range,
      lines = lines,
      fn_name = fn_name,
      config = config,
    }
  end)
  task:raise_on_error()
  if opts.preview_ns then task:wait() end
end

---@param range_type 'v' | 'V' | ''
---@param config refactor.Config
M.extract_func_to_file = function(range_type, config)
  local get_selected_range = require("refactoring.utils").get_selected_range
  local input = require("refactoring.utils").input

  local opts = config.refactor.extract_func

  local buf = api.nvim_get_current_buf()
  local selected_range = get_selected_range(buf, range_type)
  local lines = vim.fn.getregion(vim.fn.getpos "'[", vim.fn.getpos "']", { type = range_type })

  local task = async.run(function()
    local file_name = opts.input and table.remove(opts.input)
      or input {
        prompt = "New file name: ",
        completion = "file",
        default = vim.fn.expand "%:.:h" .. "/",
      }
    if not file_name then return end
    local fn_name = opts.input and table.remove(opts.input) or input { prompt = "Function name: " }
    if not fn_name then return end

    -- TODO: open the buffer somehow (configurable?) or give feedback to the
    -- user somehow?
    local out_buf = vim.fn.bufadd(file_name)
    if not api.nvim_buf_is_loaded(out_buf) then vim.fn.bufload(out_buf) end
    if not vim.bo[out_buf].buflisted then vim.bo[out_buf].buflisted = true end

    extract_func {
      in_buf = buf,
      out_buf = out_buf,
      selected_range = selected_range,
      lines = lines,
      fn_name = fn_name,
      config = config,
    }
  end)
  task:raise_on_error()
  if opts.preview_ns then task:wait() end
end

return M
