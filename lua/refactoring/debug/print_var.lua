local api = vim.api
local ts = vim.treesitter
local iter = vim.iter
local async = require "async"
local range = require "refactoring.range"
local pos = require "refactoring.pos"

local M = {}

-- TODO: add some way to list/search/travel across all inserted statements

---@class refactor.print_var.code_generation.Opts
---@field identifier string
---@field identifier_str string
---@field debug_path string
---@field count string

---@class refactor.print_var.CodeGeneration
---@field print_var {[string]: nil|fun(opts: refactor.print_var.code_generation.Opts): string}

---@class refactor.print_var.UserCodeGeneration
---@field print_var? {[string]: nil|fun(opts: refactor.print_var.code_generation.Opts): string}

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
local function get_all_print_var(buf, nested_lang_tree, start_marker, end_marker)
  local query_error = require("refactoring.utils").query_error
  local get_comments = require("refactoring.utils").get_comments

  local lang = nested_lang_tree:lang()

  local comment_query = ts.query.get(lang, "refactor_comment")
  if not comment_query then return query_error("refactor_comment", lang) end

  local comments = get_comments(buf, nested_lang_tree, comment_query)
  table.sort(comments, node_comp_asc)
  ---@type vim.Range[]
  local all_print_var = iter(comments)
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
  all_print_var.current_start = nil
  return all_print_var
end

-- TODO: think about making `refactor_output_statement` queries behave like
-- `refactor_scope` (an scope can have multiple, disjointed, nodes).
-- Or think, in general, of a way to distinguish between "this is a parameter,
-- I want `below` to mean 'inside the function'" and "this is a function name,
-- I want `below` to mean 'after the function definition'".
-- This also should take into account how the `reference_pos` is computed,
-- a statement like `vim.keymap.set('n', '<F4>', function() ...` where the
-- function continues in the next line will end in a function definition, so
-- `bellow` will be inside of the function definition. Maybe it's a better
-- idea to compute both start/end reference_pos individually for each
-- variable found in the `selected_range` (and hence, its containing
-- statement). This would change the semantics of how `print_xxx` functions
-- work. Instead of a big blob printing all of the variables, they would
-- generate many small blobs, one for each variable
---@param range_type 'v' | 'V' | ''
---@param config refactor.Config
function M.print_var(range_type, config)
  local get_selected_range = require("refactoring.utils").get_selected_range
  local code_gen_error = require("refactoring.utils").code_gen_error
  local apply_text_edits = require("refactoring.utils").apply_text_edits
  local get_declarations_by_scope = require("refactoring.utils").get_declarations_by_scope
  local scopes_for_range = require("refactoring.utils").scopes_for_range
  local get_declaration_scope = require("refactoring.utils").get_declaration_scope
  local indent = require("refactoring.utils").indent
  local get_references_info = require("refactoring.utils").get_references_info
  local get_output_statements_info = require("refactoring.utils").get_output_statements_info
  local get_scopes_info = require("refactoring.utils").get_scopes_info
  local query_error = require("refactoring.utils").query_error
  local get_statement_output_range = require("refactoring.debug.utils").get_statement_output_range
  local get_debug_path_for_range = require("refactoring.utils").get_debug_path_for_range

  local opts = config.debug.print_var
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
    -- TODO: check if using a range parses only when necessary (by peeking into
    -- the implementation, it does use `LanguageTree:valid`, but it always
    -- returns false when `range` is `true`)
    lang_tree:parse(true)
    local nested_lang_tree = lang_tree:language_for_range {
      selected_range.start_row,
      selected_range.start_col,
      selected_range.end_row,
      selected_range.end_col,
    }
    local lang = nested_lang_tree:lang()
    local reference_query = ts.query.get(lang, "refactor_reference")
    if not reference_query then return query_error("refactor_reference", lang) end
    local output_statement_query = ts.query.get(lang, "refactor_output_statement")
    if not output_statement_query then return query_error("refactor_output_statement", lang) end
    local scope_query = ts.query.get(lang, "refactor_scope")
    if not scope_query then return query_error("refactor_scope", lang) end

    local get_print_var = code_generation.print_var[lang]
    if not get_print_var then return code_gen_error("print_var", lang) end

    local references = get_references_info(buf, nested_lang_tree, reference_query)
    local output_statements = get_output_statements_info(buf, nested_lang_tree, output_statement_query)
    local scopes_info = get_scopes_info(buf, nested_lang_tree, scope_query)

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

    -- TODO: I also compute `declarations_before_output_range` in
    -- `extract_func`. Is there a cleaner wat to do all this in both places?
    local declarations_by_scope = get_declarations_by_scope(references, scopes_info, buf)
    local scopes_for_selected_range = scopes_for_range(buf, scopes_info, selected_range)
    local declarations_before_output_range = iter(references)
      :filter(
        ---@param r refactor.ReferenceInfo
        function(r)
          return r.declaration
        end
      )
      :filter(
        ---@param r refactor.ReferenceInfo
        function(r)
          local declaration_scope = get_declaration_scope(declarations_by_scope, scopes_info, r, buf)

          local is_in_scope = false
          if declaration_scope then
            is_in_scope = iter(scopes_for_selected_range):any(
              ---@param si refactor.ScopeInfo
              function(si)
                return si == declaration_scope
              end
            )
          end

          local r_srow, r_scol, r_erow, r_ecol = r.identifier:range()
          local r_range = range(r_srow, r_scol, r_erow, r_ecol, { buf = buf })
          return r_range < output_range and is_in_scope
        end
      )
      :map(
        ---@param reference refactor.ReferenceInfo
        function(reference)
          return ts.get_node_text(reference.identifier, buf)
        end
      )
      :totable()

    local debug_path_for_range = get_debug_path_for_range(buf, nested_lang_tree, output_range)
    if not debug_path_for_range then return end
    debug_path_for_range = ("┆%s┆"):format(debug_path_for_range)

    local start_marker = config.debug.markers.print_var.start
    local end_marker = config.debug.markers.print_var["end"]

    local all_print_var = get_all_print_var(buf, nested_lang_tree, start_marker, end_marker)
    if not all_print_var then return end
    ---@type {[string]: vim.Range[]|nil}
    local print_var_by_path_and_identifier = iter(all_print_var):fold(
      {},
      ---@param acc {[string]: vim.Range[]}
      ---@param r vim.Range
      function(acc, r)
        local srow, scol, erow, ecol = r:to_extmark()
        local r_lines = api.nvim_buf_get_text(buf, srow, scol, erow, ecol, {})
        local r_text = table.concat(r_lines, "\n")
        local path = r_text:match "┆([^┆]*)┆"
        local identifier = r_text:match "╎([^╎]*)╎"

        local key = ("%s_%s"):format(path, identifier)
        acc[key] = acc[key] or {}
        table.insert(acc[key], r)

        return acc
      end
    )

    ---@type refactor.ReferenceInfo[]
    local selected_references = iter(references)
      :filter(
        ---@param r refactor.ReferenceInfo
        function(r)
          local r_srow, r_scol, r_erow, r_ecol = r.identifier:range()
          local r_range = range(r_srow, r_scol, r_erow, r_ecol, { buf = buf })
          return selected_range:has(r_range)
        end
      )
      :totable()
    table.sort(selected_references, function(a, b)
      local a_srow, a_scol, a_erow, a_ecol = a.identifier:range()
      local a_range = range(a_srow, a_scol, a_erow, a_ecol, { buf = buf })
      local b_srow, b_scol, b_erow, b_ecol = b.identifier:range()
      local b_range = range(b_srow, b_scol, b_erow, b_ecol, { buf = buf })

      return a_range < b_range
    end)
    ---@type refactor.ReferenceInfo[]
    local filtered_references = iter(selected_references)
      :unique(
        ---@param r refactor.ReferenceInfo
        function(r)
          return ts.get_node_text(r.identifier, buf)
        end
      )
      :filter(
        ---@param r refactor.ReferenceInfo
        function(r)
          local identifier = ts.get_node_text(r.identifier, buf)
          return not r.function_call_identifier
            and (r.field or vim.list_contains(declarations_before_output_range, identifier))
        end
      )
      :totable()
    if #filtered_references == 0 then
      return vim.notify(
        "Couldn't find any reference inside of the extracted range with a declaration above output range using Treesitter",
        vim.log.levels.ERROR,
        { title = "refactoring.nvim" }
      )
    end
    ---@type string[]
    local print_lines = iter(filtered_references)
      :map(
        ---@param r refactor.ReferenceInfo
        function(r)
          local identifier = ts.get_node_text(r.identifier, buf)

          local p = debug_path_for_range:match "┆([^┆]*)┆"
          local key = ("%s_%s"):format(p, identifier)

          local matching_print_var = print_var_by_path_and_identifier[key] or {}
          local print_var_before = iter(matching_print_var)
            :filter(
              ---@param r vim.Range
              function(r)
                return r < output_range
              end
            )
            :totable()

          return get_print_var {
            identifier = identifier,
            identifier_str = ("╎%s╎"):format(identifier),
            debug_path = debug_path_for_range,
            count = ("┊%d┊"):format(#print_var_before + 1),
          }
        end
      )
      :totable()
    -- TODO: commenstring isn't the correct one for injected languages
    local commentstring = vim.bo[buf].commentstring
    table.insert(print_lines, 1, commentstring:format(start_marker))
    print_lines[#print_lines] = print_lines[#print_lines] .. commentstring:format(end_marker)

    local output_srow = output_range:to_extmark()
    local expandtab = vim.bo[buf].expandtab
    local _, indent_amount = indent(expandtab, 0, api.nvim_buf_get_lines(buf, output_srow, output_srow + 1, true)[1])
    local print_text = table.concat(print_lines, "\n")
    print_text = indent(expandtab, indent_amount, print_text)
    print_lines = vim.split(print_text, "\n")
    if inserted_at == "end" then table.insert(print_lines, 1, "") end
    if inserted_at == "start" then
      print_lines[1] = indent(expandtab, 0, print_lines[1])
      table.insert(print_lines, (expandtab and " " or "\t"):rep(indent_amount))
    end

    ---@type {[integer]: refactor.TextEdit[]}
    local text_edits_by_buf = {}
    text_edits_by_buf[buf] = {}
    table.insert(text_edits_by_buf[buf], { range = output_range, lines = print_lines })

    iter(filtered_references):each(
      ---@param r refactor.ReferenceInfo
      function(r)
        local identifier = ts.get_node_text(r.identifier, buf)

        local p = debug_path_for_range:match "┆([^┆]*)┆"
        local key = ("%s_%s"):format(p, identifier)

        local matching_print_var = print_var_by_path_and_identifier[key]
        if not matching_print_var then return end

        iter(ipairs(matching_print_var))
          :filter(
            ---@param r vim.Range
            function(_, r)
              return r > output_range
            end
          )
          :each(
            ---@param old_count integer
            ---@param ra vim.Range
            function(old_count, ra)
              local srow, scol, erow, ecol = ra:to_extmark()
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
      end
    )

    apply_text_edits(text_edits_by_buf)
  end)
  task:raise_on_error()
end

return M
