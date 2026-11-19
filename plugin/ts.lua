local iter = vim.iter
local ts = vim.treesitter

-- TODO: move this into another lua file in order to lazy load it with require
---@type {[string]: nil|fun(opts: {value: TSNode, source: string|integer}): string|vim.NIL|{identifier: string}}
local infer_type = {
  lua = function(opts)
    local type ---@type string|vim.NIL
    local node_type = opts.value:type()
    if node_type == "number" then
      type = "number"
    elseif node_type == "string" then
      type = "string"
    elseif node_type == "true" or node_type == "false" then
      type = "boolean"
    elseif node_type == "nil" then
      type = "nil"
    elseif node_type == "function_definition" then
      type = "function"
    elseif node_type == "table_constructor" then
      type = "table"
    elseif node_type == "identifier" then
      type = { identifier = ts.get_node_text(opts.value, opts.source) }
    else
      type = vim.NIL
    end
    return type
  end,
  javascript = function(opts)
    local type ---@type string|vim.NIL
    local node_type = opts.value:type()
    if node_type == "number" then
      type = "number"
    elseif node_type == "string" or node_type == "template_string" then
      type = "string"
    elseif node_type == "true" or node_type == "false" then
      type = "boolean"
    elseif node_type == "null" then
      type = "null"
    elseif node_type == "undefined" then
      type = "undefined"
    elseif node_type == "arrow_function" then
      -- TODO: maybe support more complex type inference for functions
      type = "() => void"
    elseif node_type == "identifier" then
      type = { identifier = ts.get_node_text(opts.value, opts.source) }
    else
      type = vim.NIL
    end
    return type
  end,
  go = function(opts)
    local type ---@type string|vim.NIL
    local node_type = opts.value:type()
    if node_type == "int_literal" then
      type = "int"
    elseif node_type == "float_literal" then
      type = "float64"
    elseif node_type == "interpreted_string_literal" then
      type = "string"
    elseif node_type == "rune_literal" then
      type = "rune"
    elseif node_type == "true" or node_type == "false" then
      type = "bool"
    elseif node_type == "composite_literal" then
      -- foo := bar{}
      local type_node = opts.value:field("type")[1]
      type = type_node and ts.get_node_text(type_node, opts.source) or vim.NIL
    elseif node_type == "func_literal" then
      -- TODO: maybe support more complex type inference for functions
      type = "func()"
    elseif node_type == "identifier" then
      type = { identifier = ts.get_node_text(opts.value, opts.source) }
    else
      type = vim.NIL
    end
    return type
  end,
  php = function(opts)
    local type ---@type string|vim.NIL
    local node_type = opts.value:type()
    if node_type == "integer" then
      type = "int"
    elseif node_type == "float" then
      type = "float"
    elseif node_type == "string" then
      type = "string"
    elseif node_type == "array_creation_expression" then
      type = "array"
    elseif node_type == "boolean" then
      type = "bool"
    elseif node_type == "null" then
      type = "null"
    elseif node_type == "anonymous_function" then
      type = "callable"
    elseif node_type == "object_creation_expression" then
      type = "object"
    elseif node_type == "identifier" then
      type = { identifier = ts.get_node_text(opts.value, opts.source) }
    else
      type = vim.NIL
    end
    return type
  end,
  rust = function(opts)
    local type ---@type string|vim.NIL
    local node_type = opts.value:type()
    local text = ts.get_node_text(opts.value, opts.source)
    if node_type == "integer_literal" and text:match "u8$" then
      type = "u8"
    elseif node_type == "integer_literal" and text:match "u16$" then
      type = "u16"
    elseif node_type == "integer_literal" and text:match "u32$" then
      type = "u32"
    elseif node_type == "integer_literal" and text:match "u64$" then
      type = "u64"
    elseif node_type == "integer_literal" and text:match "u128$" then
      type = "u128"
    elseif node_type == "integer_literal" and text:match "usize$" then
      type = "usize"
    elseif node_type == "integer_literal" and text:match "i8$" then
      type = "i8"
    elseif node_type == "integer_literal" and text:match "i16$" then
      type = "i16"
    elseif node_type == "integer_literal" and text:match "i32$" then
      type = "i32"
    elseif node_type == "integer_literal" and text:match "i64$" then
      type = "i64"
    elseif node_type == "integer_literal" and text:match "i128$" then
      type = "i128"
    elseif node_type == "integer_literal" and text:match "isize$" then
      type = "isize"
    elseif node_type == "float_literal" and text:match "f32$" then
      type = "f32"
    elseif node_type == "float_literal" and text:match "f64$" then
      type = "f64"
    elseif node_type == "integer_literal" then
      type = "i32"
    elseif node_type == "float_literal" then
      type = "f64"
    elseif node_type == "string_literal" or node_type == "raw_string_literal" then
      type = "&str"
    elseif node_type == "char_literal" then
      type = "char"
    elseif node_type == "boolean_literal" then
      type = "bool"
    elseif node_type == "identifier" then
      type = { identifier = ts.get_node_text(opts.value, opts.source) }
    else
      type = vim.NIL
    end
    return type
  end,
}
infer_type.typescript = infer_type.javascript

ts.query.add_directive("infer-type!", function(match, pattern, source, predicate, metadata)
  local lang = predicate[2] --[[@as string]]
  local values_id = predicate[3]

  local values = match[values_id]
  local infer_type_lang = infer_type[lang]
  if not infer_type_lang then return end
  local types = iter(values)
    :map(function(value)
      return infer_type_lang { value = value, source = source }
    end)
    :totable()
  metadata.types = types
end, { force = true, all = true })

-- TODO: move this into another lua file in order to lazy load it with require
---@type {[string]: nil|fun(opts: {types: TSNode[]?, identifiers: TSNode[], source: integer|string}): string[]|nil}
local get_type = {
  c = function(opts)
    if not opts.types then return end
    local types ---@type string[]
    if #opts.types == #opts.identifiers then
      types = iter(opts.types)
        :map(
          ---@param n TSNode
          function(n)
            return ts.get_node_text(n, opts.source)
          end
        )
        :totable()
    else
      local type = ts.get_node_text(opts.types[1], opts.source)
      types = iter(opts.identifiers)
        :map(function()
          return type
        end)
        :totable()
    end
    return types
  end,
  typescript = function(opts)
    if not opts.types then return end
    return iter(opts.types)
      :map(
        ---@param t TSNode
        function(t)
          return ts.get_node_text(t, opts.source)
        end
      )
      :totable()
  end,
  rust = function(opts)
    if not opts.types then return end
    return iter(opts.types)
      :map(
        ---@param t TSNode
        function(t)
          local text = ts.get_node_text(t, opts.source)
          if t:type() ~= "self_parameter" then return text end
          if text == "&self" then return "&Self" end
          if text == "mut self" then return "Self" end
          if text == "&mut self" then return "&mut Self" end
          error(("Unexpected text %s for self_parameter for rust"):format(text))
        end
      )
      :totable()
  end,
}
get_type.c_sharp = get_type.c
get_type.go = get_type.c
get_type.java = get_type.c
get_type.kotlin = get_type.c
get_type.php = get_type.c
get_type.python = get_type.c

ts.query.add_directive("set-type!", function(match, pattern, source, predicate, metadata)
  local lang = predicate[2] --[[@as string]]
  local type_id = predicate[3]
  local identifier_id = predicate[4]
  local get_type_lang = get_type[lang]
  if not get_type_lang then return end
  local types = get_type_lang {
    types = match[type_id],
    identifiers = match[identifier_id],
    source = source,
  }
  if not types then return end
  metadata.types = types
end, { force = true, all = true })
