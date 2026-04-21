local iter = vim.iter
local ts = vim.treesitter
local api = vim.api
local async = require "async"
local pos = require "refactoring.pos"
local range = require "refactoring.range"

local M = {}

---@class refactor.inline_var.code_generation.group_expression.Opts
---@field expression string

---@class refactor.inline_var.CodeGeneration
---@field group_expression {[string]: nil|fun(opts: refactor.inline_var.code_generation.group_expression.Opts): string}

---@class refactor.inline_var.UserCodeGeneration
---@field group_expression? {[string]: nil|fun(opts: refactor.inline_var.code_generation.group_expression.Opts): string}

---@param definition refactor.QfItem
---@param variables_info refactor.VariableInfo[]
---@return nil|refactor.ProcessedVariableInfo
local function get_definition_info(definition, variables_info)
  local definition_buf = vim.fn.bufadd(definition.filename)

  -- TODO: add pos.vimscript
  local definition_start = pos(definition.lnum - 1, definition.col - 1, { buf = definition_buf })
  ---@type refactor.ProcessedVariableInfo
  local variable_info = iter(variables_info)
    :map(
      ---@param info refactor.VariableInfo
      function(info)
        local variable_info = iter(ipairs(info.identifier))
          :filter(
            ---@param _ integer
            ---@param identifier TSNode
            function(_, identifier)
              local srow, scol, erow, ecol = identifier:range()
              local identifier_range = range(srow, scol, erow, ecol, { buf = definition_buf })
              return identifier_range:has(definition_start)
            end
          )
          :map(
            ---@param i integer
            ---@param identifier TSNode
            ---@return refactor.ProcessedVariableInfo
            function(i, identifier)
              return {
                identifier = identifier,
                identifier_separator = info.identifier_separator
                  and (info.identifier_separator[i] or info.identifier_separator[i - 1]),
                value = info.value[i],
                value_separator = info.value_separator and (info.value_separator[i] or info.value_separator[i - 1]),
                -- NOTE: captures must only have one declaration
                declaration = info.declaration[1],
              }
            end
          )
          :next()
        return variable_info
      end
    )
    :filter(
      ---@param variable_info refactor.ProcessedVariableInfo
      function(variable_info)
        return variable_info ~= nil
      end
    )
    :next()

  return variable_info
end

---@class refactor.inline_var.MatchInfo
---@field variables refactor.VariableInfo[]
---@field references refactor.ReferenceInfo[]

--As a side effect, loads all the buffers for all of the definitions and references
---@param definitions refactor.QfItem[]
---@param references refactor.QfItem[]
---@param lang string
---@return nil|{[integer]: refactor.inline_var.MatchInfo}
local function get_match_info(definitions, references, lang)
  local get_references_info = require("refactoring.utils").get_references_info
  local get_variables_info = require("refactoring.utils").get_variables_info
  local query_error = require("refactoring.utils").query_error

  local reference_query = ts.query.get(lang, "refactor_reference")
  if not reference_query then return query_error("refactor_reference", lang) end
  local variable_query = ts.query.get(lang, "refactor_variable")
  if not variable_query then return query_error("refactor_variable", lang) end

  ---@type {[integer]: refactor.inline_var.MatchInfo}
  local match_info = iter({ definitions, references })
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

        local variables_info = get_variables_info(buf, lang_tree, variable_query)
        local references_info = get_references_info(buf, lang_tree, reference_query)

        return buf, { variables = variables_info, references = references_info }
      end
    )
    :fold(
      {},
      ---@param acc {[integer]: refactor.inline_var.MatchInfo}
      ---@param k integer
      ---@param v nil|refactor.inline_var.MatchInfo
      function(acc, k, v)
        acc[k] = v
        return acc
      end
    )
  return match_info
end

---@class refactor.VariableInfo
---@field identifier TSNode[]
---@field identifier_separator TSNode[]|nil
---@field value TSNode[]
---@field value_separator TSNode[]|nil
---@field declaration TSNode[]

---@class refactor.ProcessedVariableInfo
---@field identifier TSNode
---@field identifier_separator TSNode|nil
---@field value TSNode
---@field value_separator TSNode|nil
---@field declaration TSNode

-- TODO: success message (can be disabled in config)
---@param config refactor.Config
function M.inline_var(_, config)
  local apply_text_edits = require("refactoring.utils").apply_text_edits
  local select = require("refactoring.utils").select
  local get_definitions = require("refactoring.utils").get_definitions
  local get_references = require("refactoring.utils").get_references
  local code_gen_error = require("refactoring.utils").code_gen_error

  local opts = config.refactor.inline_var
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

  local task = async.run(function()
    local results = async.await_all {
      async.run(get_definitions),
      async.run(get_references),
    }
    local definitions = unpack(results[1]) ---@type refactor.QfItem[]
    local references = unpack(results[2]) ---@type refactor.QfItem[]

    local match_info_by_buf = get_match_info(definitions, references, lang)
    if not match_info_by_buf then return end

    local get_grouped_expression = code_generation.group_expression[lang]
    if not get_grouped_expression then return code_gen_error("group_expression", lang) end

    ---@type {definition: refactor.QfItem, info: refactor.ProcessedVariableInfo}[]
    local definitions_with_info = iter(definitions)
      :map(
        ---@param d refactor.QfItem
        function(d)
          local definition_buf = vim.fn.bufadd(d.filename)
          local variables_info = match_info_by_buf[definition_buf].variables
          local definition_info = get_definition_info(d, variables_info)
          return { definition = d, info = definition_info }
        end
      )
      :filter(
        ---@param dwi {definition: refactor.QfItem, info: refactor.ProcessedVariableInfo|nil}
        function(dwi)
          return dwi.info ~= nil
        end
      )
      :totable()

    if #definitions_with_info == 0 then
      vim.notify("Couldn't find the definition of the symbol under cursor using treesitter", vim.log.levels.ERROR)
      return
    end
    local definition_with_info = #definitions_with_info == 1 and definitions_with_info[1]
      or select(definitions_with_info, {
        prompt = "Mutliple definitions found, select one",
        format_item =
          ---@param item {definition: refactor.QfItem, info: refactor.ProcessedVariableInfo}
          function(item)
            local buf = vim.fn.bufadd(item.definition.filename)
            return ts.get_node_text(item.info.declaration, buf)
          end,
      })
    if not definition_with_info then return end

    local definition, definition_info = definition_with_info.definition, definition_with_info.info
    local definition_buf = vim.fn.bufadd(definition.filename)
    -- TODO: add pos.vimscript
    local definition_start = pos(definition.lnum - 1, definition.col - 1, { buf = definition_buf })

    ---@type {reference: refactor.QfItem, info: refactor.ReferenceInfo|nil}[]
    local references_with_info = iter(references)
      :unique(
        ---@param r refactor.QfItem
        function(r)
          return ("%d-%d-%d-%d"):format(r.lnum, r.col, r.end_lnum, r.end_col)
        end
      )
      :filter(
        ---@param r refactor.QfItem
        function(r)
          local r_buf = vim.fn.bufadd(r.filename)
          if r_buf ~= definition_buf then return true end

          -- TODO: add range.vimscript
          local r_range = range(r.lnum - 1, r.col - 1, r.end_lnum - 1, r.end_col - 1, { buf = r_buf })
          return not r_range:has(definition_start)
        end
      )
      :map(
        ---@param r refactor.QfItem
        function(r)
          local reference_buf = vim.fn.bufadd(r.filename)
          -- TODO: add range.vimscript
          local reference_range = range(r.lnum - 1, r.col - 1, r.end_lnum - 1, r.end_col - 1, { buf = reference_buf })

          local references_info = match_info_by_buf[reference_buf].references
          local reference_info = iter(references_info)
            :filter(
              ---@param ri refactor.ReferenceInfo
              function(ri)
                local srow, scol, erow, ecol = ri.identifier:range()
                local identifier_range = range(srow, scol, erow, ecol, { buf = reference_buf })
                return identifier_range:has(reference_range)
              end
            )
            :fold(
              nil,
              ---@param acc nil|refactor.ReferenceInfo
              ---@param ri refactor.ReferenceInfo
              function(acc, ri)
                if not acc then return ri end
                if ri.identifier:byte_length() < acc.identifier:byte_length() then return ri end
                return acc
              end
            )

          return { reference = r, info = reference_info }
        end
      )
      :filter(
        ---@param rwi {reference: refactor.QfItem, info: refactor.ReferenceInfo|nil}
        function(rwi)
          return rwi.info ~= nil
        end
      )
      :totable()

    local declaration_node = definition_info.declaration
    local identifier_node = definition_info.identifier
    local value_node = definition_info.value

    local value_text = ts.get_node_text(value_node, definition_buf)
    local grouped_value_text = get_grouped_expression { expression = value_text }

    ---@type {[integer]: refactor.TextEdit[]}
    local text_edits_by_buf = {}
    iter(references_with_info):each(
      ---@param rwi {reference: refactor.QfItem, info: refactor.ReferenceInfo|nil}
      function(rwi)
        local reference = rwi.reference
        local buf = vim.fn.bufadd(reference.filename)
        local srow, scol, erow, ecol = rwi.info.identifier:range()
        local identifier_range = range(srow, scol, erow, ecol, { buf = buf })

        text_edits_by_buf[buf] = text_edits_by_buf[buf] or {}
        table.insert(text_edits_by_buf[buf], {
          range = identifier_range,
          lines = vim.split(grouped_value_text, "\n"),
        })
      end
    )

    if definition_info.value_separator or definition_info.identifier_separator then
      iter({
          definition_info.value_separator,
          value_node,
          definition_info.identifier_separator,
          identifier_node,
        })
        :filter(function(n)
          return n ~= nil
        end)
        :map(
          ---@param n TSNode
          function(n)
            local srow, scol, erow, ecol = n:range()
            return range(srow, scol, erow, ecol, { buf = definition_buf })
          end
        )
        :each(
          ---@param r vim.Range
          function(r)
            text_edits_by_buf[definition_buf] = text_edits_by_buf[definition_buf] or {}
            table.insert(text_edits_by_buf[definition_buf], { range = r, lines = {} })
          end
        )
    else
      local srow, scol, erow, ecol = declaration_node:range()
      local declaration_line = api.nvim_buf_get_lines(0, erow, erow + 1, true)[1]

      local should_delete_trailling_newline = ecol > 0 and ecol == #declaration_line
      if should_delete_trailling_newline then
        erow = erow + 1
        ecol = 0
      end
      local should_delete_leading_whitespace = scol > 0 and declaration_line:sub(1, scol):match "^%s+$" ~= nil
      if should_delete_leading_whitespace then scol = 0 end

      local declaration_range = range(srow, scol, erow, ecol, { buf = definition_buf })
      text_edits_by_buf[definition_buf] = text_edits_by_buf[definition_buf] or {}
      table.insert(text_edits_by_buf[definition_buf], { range = declaration_range, lines = {} })
    end

    apply_text_edits(text_edits_by_buf)
  end)
  task:raise_on_error()
  if opts.preview_ns then task:wait() end
end

return M
