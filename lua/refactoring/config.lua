local iter = vim.iter

local M = {}

---@class refactor.refactor.Config
---@field extract_func refactor.refactor.extract_func.Opts
---@field extract_var refactor.refactor.extract_var.Opts
---@field inline_func refactor.refactor.inline_func.Opts
---@field inline_var refactor.refactor.inline_var.Opts

---@class refactor.refactor.UserConfig
---@field extract_func? refactor.refactor.extract_func.UserOpts
---@field extract_var? refactor.refactor.extract_var.UserOpts
---@field inline_func? refactor.refactor.inline_func.UserOpts
---@field inline_var? refactor.refactor.inline_var.UserOpts

---@class refactor.debug.Config
---@field markers refactor.debug.Markers
---@field cleanup refactor.debug.cleanup.Opts
---@field print_var refactor.debug.print_var.Opts
---@field print_loc refactor.debug.print_loc.Opts
---@field print_exp refactor.debug.print_exp.Opts

---@class refactor.debug.UserConfig
---@field markers? refactor.debug.UserMarkers
---@field cleanup? refactor.debug.cleanup.UserOpts
---@field print_var? refactor.debug.print_var.UserOpts
---@field print_loc? refactor.debug.print_loc.UserOpts

---@class refactor.Config
---@field show_success_message boolean
---@field refactor refactor.refactor.Config
---@field debug refactor.debug.Config

---@class refactor.UserConfig
---@field show_success_message? boolean
---@field refactor? refactor.refactor.UserConfig
---@field debug? refactor.debug.UserConfig

---@type refactor.extract_var.CodeGeneration
local extract_var_code_generation = {
  variable_declaration = {
    lua = function(opts)
      return ("local %s = %s"):format(opts.name, opts.value)
    end,
    javascript = function(opts)
      return ("const %s = %s;"):format(opts.name, opts.value)
    end,
    c = function(opts)
      return ("P %s = %s;"):format(opts.name, opts.value)
    end,
    c_sharp = function(opts)
      return ("var %s = %s;"):format(opts.name, opts.value)
    end,
    go = function(opts)
      return ("%s := %s"):format(opts.name, opts.value)
    end,
    java = function(opts)
      return ("var %s = %s;"):format(opts.name, opts.value)
    end,
    php = function(opts)
      return ("$%s = %s;"):format(opts.name, opts.value)
    end,
    python = function(opts)
      return ("%s = %s"):format(opts.name, opts.value)
    end,
    ruby = function(opts)
      return ("%s = %s"):format(opts.name, opts.value)
    end,
    vim = function(opts)
      return ("let l:%s = %s"):format(opts.name, opts.value)
    end,
    powershell = function(opts)
      return ("$%s = %s"):format(opts.name, opts.value)
    end,
  },
  variable = {
    php = function(opts)
      return ("$%s"):format(opts.name)
    end,
    vim = function(opts)
      return ("l:%s"):format(opts.name)
    end,
    powershell = function(opts)
      return ("$%s"):format(opts.name)
    end,
  },
}
extract_var_code_generation.variable_declaration.typescript =
  extract_var_code_generation.variable_declaration.javascript
extract_var_code_generation.variable_declaration.cpp = extract_var_code_generation.variable_declaration.c

---@type refactor.extract_func.CodeGeneration
local extract_func_code_generation = {
  function_declaration = {
    lua = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      local has_arg_types = iter(opts.args):any(
        ---@param v refactor.Variable
        function(v)
          return v.type ~= nil
        end
      )
      local annotations = not has_arg_types and ""
        or iter(opts.args)
            :filter(
              ---@param v refactor.Variable
              function(v)
                return v.type ~= nil
              end
            )
            :map(
              ---@param v refactor.Variable
              function(v)
                return ("---@param %s %s"):format(v.identifier, v.type)
              end
            )
            :join "\n"
          .. "\n"

      return ([[
%slocal function %s(%s)
%s
end]]):format(annotations, opts.name, args, opts.body)
    end,
    c = function(opts)
      local return_type = #opts.return_values == 1 and (opts.return_values[1].type or "P") or "void"
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return ("%s %s"):format(v.type or "P", v.identifier)
          end
        )
        :join ", "
      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.type and ("%s *%s"):format(v.type, v.identifier) or ("P *%s"):format(v.identifier)
          end
        )
        :join ", "
      local in_n_out = args ~= "" and table.concat({ args, return_values }, ", ") or return_values

      return ([[
%s %s(%s) {
%s
}]]):format(return_type, opts.name, #opts.return_values < 2 and args or in_n_out, opts.body)
    end,
    c_sharp = function(opts)
      local return_type = #opts.return_values == 1 and (opts.return_values[1].type or "P")
        or #opts.return_values == 0 and "void"
        or ("(%s)"):format(iter(opts.return_values)
          :map(
            ---@param v refactor.Variable
            function(v)
              return v.type or "P"
            end
          )
          :join ", ")

      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return ("%s %s"):format(v.type or "P", v.identifier)
          end
        )
        :join ", "

      return ([[
public %s %s(%s) {
%s
}]]):format(return_type, opts.name, args, opts.body)
    end,
    javascript = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      local has_arg_types = iter(opts.args):any(
        ---@param v refactor.Variable
        function(v)
          return v.type ~= nil
        end
      )
      local annotations = ""

      if has_arg_types then
        annotations = iter(opts.args)
          :filter(
            ---@param v refactor.Variable
            function(v)
              return v.type ~= nil
            end
          )
          :map(
            ---@param v refactor.Variable
            function(v)
              return ("* @param {%s} %s"):format(v.type, v.identifier)
            end
          )
          :join "\n"
        annotations = ([[
/**
%s
*/
]]):format(annotations)
      end
      return ([[
%s%s%s(%s){
%s
}]]):format(annotations, opts.method and "" or "function ", opts.name, args, opts.body)
    end,
    typescript = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.type and ("%s: %s"):format(v.identifier, v.type) or v.identifier
          end
        )
        :join ", "
      return ([[
%s%s(%s){
%s
}]]):format(opts.method and "" or "function ", opts.name, args, opts.body)
    end,
    go = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return ("%s %s"):format(v.identifier, v.type or "P")
          end
        )
        :join ", "
      local struct = (opts.struct_name and opts.struct_var_name)
          and (" (%s *%s)"):format(opts.struct_var_name, opts.struct_name)
        or ""
      local return_type = #opts.return_values == 0 and ""
        or #opts.return_values == 1 and (" %s"):format(opts.return_values[1].type or "P")
        or (" (%s)"):format(iter(opts.return_values)
          :map(
            ---@param v refactor.Variable
            function(v)
              return v.type or "P"
            end
          )
          :join ", ")
      return ([[
func%s %s(%s)%s {
%s
}]]):format(struct, opts.name, args, return_type, opts.body)
    end,
    java = function(opts)
      local return_type = #opts.return_values == 0 and "void" or (opts.return_values[1].type or "P")
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return ("%s %s"):format(v.type or "P", v.identifier)
          end
        )
        :join ", "
      return ([[
private %s %s(%s) {
%s
}]]):format(return_type, opts.name, args, opts.body)
    end,
    php = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.type and ("%s %s"):format(v.type, v.identifier) or v.identifier
          end
        )
        :join ", "
      return ([[
%sfunction %s(%s)
{
%s
}]]):format(opts.method and "private " or "", opts.name, args, opts.body)
    end,
    powershell = function(opts)
      if opts.method then
        local args = iter(opts.args)
          :map(
            ---@param v refactor.Variable
            function(v)
              return v.identifier
            end
          )
          :join ", "
        return ([[
[%s] %s(%s)
{
%s
}]]):format(
          #opts.return_values == 0 and "Void" or (opts.return_values[1].type or "P"),
          opts.name,
          args,
          opts.body
        )
      end
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ",\n"
      return ([[
function %s
{
param (%s)
%s
}]]):format(opts.name, args, opts.body)
    end,
    python = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      if opts.method then args = "self, " .. args end
      return ([[
def %s(%s):
%s]]):format(opts.name, args, opts.body)
    end,
    ruby = function(opts)
      local name = opts.singleton and "self." .. opts.name or opts.name
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ([[
def %s(%s):
%s
end]]):format(name, args, opts.body)
    end,
    vim = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param a refactor.Variable
          function(a)
            return a.identifier
          end
        )
        :join ", "
      return ([[
function! s:%s(%s) abort
%s
endfunction]]):format(opts.name, args, opts.body)
    end,
  },
  function_call = {
    lua = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "

      if #opts.return_values == 0 then return ("%s(%s)"):format(opts.name, args) end

      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("local %s = %s(%s)"):format(return_values, opts.name, args)
    end,
    c = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      if #opts.return_values == 0 then return ("%s(%s);"):format(opts.name, args) end
      if #opts.return_values == 1 then
        return ("%s %s = %s(%s);"):format(
          opts.return_values[1].type or "P",
          opts.return_values[1].identifier,
          opts.name,
          args
        )
      end
      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return "&" .. v.identifier
          end
        )
        :join ", "
      local in_n_out = args ~= "" and table.concat({ args, return_values }, ", ") or return_values
      return ("%s(%s);"):format(opts.name, in_n_out)
    end,
    c_sharp = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      if #opts.return_values == 0 then return ("%s(%s);"):format(opts.name, args) end
      if #opts.return_values == 1 then
        return ("%s %s = %s(%s);"):format(
          opts.return_values[1].type or "var",
          opts.return_values[1].identifier,
          opts.name,
          args
        )
      end
      return ("var out = %s(%s);"):format(opts.name, args)
    end,
    javascript = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      local name = opts.method and ("this.%s"):format(opts.name) or opts.name

      if #opts.return_values == 0 then return ("%s(%s);"):format(name, args) end
      if #opts.return_values == 1 then
        return ("let %s = %s(%s);"):format(opts.return_values[1].identifier, name, args)
      end
      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("let [%s] = %s(%s);"):format(return_values, name, args)
    end,
    go = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      local name = opts.struct_var_name and ("%s.%s"):format(opts.struct_var_name, opts.name) or opts.name
      if #opts.return_values == 0 then return ("%s(%s)"):format(name, args) end

      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("%s := %s(%s)"):format(return_values, name, args)
    end,
    java = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      if #opts.return_values == 0 then return ("%s(%s);"):format(opts.name, args) end

      if #opts.return_values > 1 then
        vim.notify(
          "The extracted function requires multiple return values, but Java lacks support for it",
          vim.log.levels.WARN,
          { title = "refactoring.nvim" }
        )
      end

      return ("var %s = %s(%s);"):format(opts.return_values[1].identifier, opts.name, args)
    end,
    php = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      local name = opts.method and "self->" .. opts.name or opts.name
      if #opts.return_values == 0 then return ("%s(%s);"):format(name, args) end
      if #opts.return_values == 1 then return ("%s = %s(%s);"):format(opts.return_values[1].identifier, name, args) end

      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("[%s] = %s(%s);"):format(return_values, name, args)
    end,
    powershell = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join " "
      if #opts.return_values == 0 then return ("%s %s"):format(opts.name, args) end
      if #opts.return_values == 1 then
        return ("%s = %s %s"):format(opts.return_values[1].identifier, opts.name, args)
      end

      return ("$out = %s %s"):format(opts.name, args)
    end,
    python = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      local name = opts.method and "self." .. opts.name or opts.name
      if #opts.return_values == 0 then return ("%s(%s)"):format(name, args) end
      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("%s = %s(%s)"):format(return_values, name, args)
    end,
    ruby = function(opts)
      local args = iter(opts.args)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      if #opts.return_values == 0 then return ("%s(%s)"):format(opts.name, args) end
      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("%s = %s(%s)"):format(return_values, opts.name, args)
    end,
    vim = function(opts)
      local return_values = #opts.return_values == 0 and "call"
        or #opts.return_values == 1 and ("let %s ="):format(opts.return_values[1].identifier)
        or ("let [%s] ="):format(iter(opts.return_values)
          :map(
            ---@param r refactor.Variable
            function(r)
              return r.identifier
            end
          )
          :join ", ")
      local args = iter(opts.args)
        :map(
          ---@param a refactor.Variable
          function(a)
            return a.identifier
          end
        )
        :join ", "
      return ([[%s %s(%s)]]):format(return_values, opts.name, args)
    end,
  },
  return_statement = {
    lua = function(opts)
      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("\n\nreturn %s"):format(return_values)
    end,
    c = function(opts)
      if #opts.return_values > 1 then return "" end

      return ("\n\nreturn %s;"):format(opts.return_values[1].identifier)
    end,
    c_sharp = function(opts)
      if #opts.return_values == 1 then return ("\n\nreturn %s;"):format(opts.return_values[1].identifier) end
      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("\n\nreturn (%s);"):format(return_values)
    end,
    javascript = function(opts)
      if #opts.return_values == 1 then return ("\n\nreturn %s;"):format(opts.return_values[1].identifier) end
      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("\n\nreturn [%s];"):format(return_values)
    end,
    go = function(opts)
      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("\n\nreturn %s"):format(return_values)
    end,
    java = function(opts)
      return ("\n\nreturn %s;"):format(opts.return_values[1].identifier)
    end,
    php = function(opts)
      if #opts.return_values == 1 then return ("\n\nreturn %s;"):format(opts.return_values[1].identifier) end

      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("\n\nreturn [%s];"):format(return_values)
    end,
    powershell = function(opts)
      if #opts.return_values == 1 then return ("\n\nreturn %s"):format(opts.return_values[1].identifier) end

      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("\n\nreturn @(%s)"):format(return_values)
    end,
    python = function(opts)
      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("\n\nreturn %s"):format(return_values)
    end,
    ruby = function(opts)
      local return_values = iter(opts.return_values)
        :map(
          ---@param v refactor.Variable
          function(v)
            return v.identifier
          end
        )
        :join ", "
      return ("\n\nreturn %s"):format(return_values)
    end,
    vim = function(opts)
      local return_values = #opts.return_values == 1 and opts.return_values[1].identifier
        or ("[%s]"):format(iter(opts.return_values)
          :map(
            ---@param r refactor.Variable
            function(r)
              return r.identifier
            end
          )
          :join ", ")
      return ([[return %s]]):format(return_values)
    end,
  },
}
extract_func_code_generation.function_declaration.cpp = extract_func_code_generation.function_declaration.c
extract_func_code_generation.function_call.cpp = extract_func_code_generation.function_call.c
extract_func_code_generation.return_statement.cpp = extract_func_code_generation.return_statement.c
extract_func_code_generation.function_call.typescript = extract_func_code_generation.function_call.javascript
extract_func_code_generation.return_statement.typescript = extract_func_code_generation.return_statement.javascript

---@type refactor.inline_func.CodeGeneration
local inline_func_code_generation = {
  assignment = {
    lua = function(opts)
      if #opts.left == 0 then return "" end

      if #opts.left < #opts.right then
        for _ = #opts.left + 1, #opts.right do
          table.remove(opts.right)
        end
      elseif #opts.right < #opts.left then
        for _ = #opts.right + 1, #opts.left do
          table.insert(opts.right, "nil")
        end
      end

      local left = table.concat(opts.left, ", ")
      local right = table.concat(opts.right, ", ")
      return ("local %s = %s"):format(left, right)
    end,
  },
}

---@type refactor.print_var.CodeGeneration
local print_var_code_generation = {
  print_var = {
    lua = function(opts)
      return ("print([==[%s %s %s:]==], vim.inspect(%s))"):format(
        opts.debug_path,
        opts.identifier_str,
        opts.count,
        opts.identifier
      )
    end,
    c = function(opts)
      return ([[printf("%s %s %s: %%s \n", %s);]]):format(
        opts.debug_path,
        opts.identifier_str,
        opts.count,
        opts.identifier
      )
    end,
    javascript = function(opts)
      return ([[console.log("%s %s %s:", %s)]]):format(
        opts.debug_path:gsub('"', '\\"'),
        opts.identifier_str:gsub('"', '\\"'),
        opts.count,
        opts.identifier
      )
    end,
    powershell = function(opts)
      return ([[Write-Host '%s %s %s:' %s ]]):format(opts.debug_path, opts.identifier_str, opts.count, opts.identifier)
    end,
    python = function(opts)
      return ([[print(f"%s %s %s: {str(%s)}")]]):format(
        opts.debug_path,
        opts.identifier_str,
        opts.count,
        opts.identifier
      )
    end,
    vim = function(opts)
      return ([[echom '%s %s %s:' %s|]]):format(opts.debug_path, opts.identifier_str, opts.count, opts.identifier)
    end,
    go = function(opts)
      return ([[fmt.Println(fmt.Sprintf("%s %s %s: %%v", %s))]]):format(
        opts.debug_path,
        opts.identifier_str,
        opts.count,
        opts.identifier
      )
    end,
    c_sharp = function(opts)
      return ([[Console.WriteLine($"%s %s %s: {%s}");]]):format(
        opts.debug_path,
        opts.identifier_str,
        opts.count,
        opts.identifier
      )
    end,
  },
}
print_var_code_generation.print_var.cpp = print_var_code_generation.print_var.c
print_var_code_generation.print_var.typescript = print_var_code_generation.print_var.javascript
print_var_code_generation.print_var.tsx = print_var_code_generation.print_var.javascript

---@type refactor.print_loc.CodeGeneration
local print_loc_code_generation = {
  print_loc = {
    lua = function(opts)
      return ([[print([==[%s %s]==])]]):format(opts.debug_path, opts.count)
    end,
    c = function(opts)
      return ([[printf("%s %s\n");]]):format(opts.debug_path, opts.count)
    end,
    javascript = function(opts)
      return ([[console.log("%s %s")]]):format(opts.debug_path, opts.count)
    end,
    powershell = function(opts)
      return ([[Write-Host '%s %s']]):format(opts.debug_path, opts.count)
    end,
    python = function(opts)
      return ([[print(f"%s %s")]]):format(opts.debug_path, opts.count)
    end,
    vim = function(opts)
      return ([[echom '%s %s'|]]):format(opts.debug_path, opts.count)
    end,
    go = function(opts)
      return ([[fmt.Println("%s %s")]]):format(opts.debug_path, opts.count)
    end,
    c_sharp = function(opts)
      return ([[Console.WriteLine(@"%s %s");]]):format(opts.debug_path, opts.count)
    end,
  },
}

-- TODO: escape `opts.expression` inside of literal string for all languages
---@type refactor.print_exp.CodeGeneration
local print_exp_code_generation = {
  print_exp = {
    lua = function(opts)
      return ("print([==[%s %s %s:]==], vim.inspect(%s))"):format(
        opts.debug_path,
        opts.expression_str,
        opts.count,
        opts.expression
      )
    end,
    c = function(opts)
      return ([[printf("%s %s %s: %%s \n", %s);]]):format(
        opts.debug_path,
        opts.expression_str,
        opts.count,
        opts.expression
      )
    end,
    javascript = function(opts)
      return ([[console.log("%s %s %s:", %s)]]):format(
        opts.debug_path:gsub('"', '\\"'),
        opts.expression_str:gsub('"', '\\"'),
        opts.count,
        opts.expression
      )
    end,
    powershell = function(opts)
      return ([[Write-Host '%s %s %s:' %s ]]):format(opts.debug_path, opts.expression_str, opts.count, opts.expression)
    end,
    python = function(opts)
      return ([[print(f"%s %s %s: {str(%s)}")]]):format(
        opts.debug_path,
        opts.expression_str,
        opts.count,
        opts.expression
      )
    end,
    vim = function(opts)
      return ([[echom '%s %s %s:' %s|]]):format(opts.debug_path, opts.expression_str, opts.count, opts.expression)
    end,
    go = function(opts)
      return ([[fmt.Println(fmt.Sprintf("%s %s %s: %%v", %s))]]):format(
        opts.debug_path,
        opts.expression_str,
        opts.count,
        opts.expression
      )
    end,
    c_sharp = function(opts)
      return ([[Console.WriteLine($"%s %s %s: {%s}");]]):format(
        opts.debug_path,
        opts.expression_str,
        opts.count,
        opts.expression
      )
    end,
  },
}

---@type refactor.inline_var.CodeGeneration
local inline_var_code_generation = {
  group_expression = {
    lua = function(opts)
      return ("(%s)"):format(opts.expression)
    end,
    c = function(opts)
      return ("(%s)"):format(opts.expression)
    end,
    javascript = function(opts)
      return ("(%s)"):format(opts.expression)
    end,
    powershell = function(opts)
      return ("(%s)"):format(opts.expression)
    end,
    python = function(opts)
      return ("(%s)"):format(opts.expression)
    end,
    vim = function(opts)
      return ("(%s)"):format(opts.expression)
    end,
    go = function(opts)
      return ("(%s)"):format(opts.expression)
    end,
  },
}

---@type refactor.Config
local default_config = {
  show_success_message = true,
  refactor = {
    extract_func = {
      code_generation = extract_func_code_generation,
    },
    inline_func = {
      code_generation = inline_func_code_generation,
    },
    extract_var = {
      code_generation = extract_var_code_generation,
    },
    inline_var = {
      code_generation = inline_var_code_generation,
    },
  },
  debug = {
    markers = {
      print_var = { start = "__PRINT_VAR_START", ["end"] = "__PRINT_VAR_END" },
      print_exp = { start = "__PRINT_EXP_START", ["end"] = "__PRINT_EXP_END" },
      print_loc = { start = "__PRINT_LOC_START", ["end"] = "__PRINT_LOC_END" },
    },
    print_var = {
      output_location = "below",
      code_generation = print_var_code_generation,
    },
    cleanup = {
      types = { "print_var", "print_loc", "print_exp" },
      restore_view = true,
    },
    print_loc = {
      output_location = "below",
      code_generation = print_loc_code_generation,
    },
    print_exp = {
      output_location = "below",
      code_generation = print_exp_code_generation,
    },
  },
}

---@type refactor.Config
local user_config = vim.deepcopy(default_config)

---@param opts? refactor.UserConfig
function M.setup(opts)
  user_config = vim.tbl_deep_extend("force", default_config, opts or {})
end

---@param buf integer
---@param opts? refactor.UserConfig
---@return refactor.Config
function M.get_config(buf, opts)
  return vim.tbl_deep_extend("force", user_config, vim.b[buf].refactor_config or {}, opts or {})
end

return M
