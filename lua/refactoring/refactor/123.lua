-- Some other suggestions
-- You should remove lsp_utils and change it to: text_edits.*
--  this will make it much less confusing. It's not really about LSP,
--  it's just about using one of the data structures.
local Pipeline = require("refactoring.pipeline")
local Region = require("refactoring.region")
local post_refactor = require("refactoring.tasks.post_refactor")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local selection_setup = require("refactoring.tasks.selection_setup")
local node_on_cursor_setup = require("refactoring.tasks.node_on_cursor_setup")
local get_select_input = require("refactoring.get_select_input")

local lsp_utils = require("refactoring.lsp_utils")

local ts_locals = require("refactoring.ts-locals")

local M = {}

---@param identifiers TSNode[]
---@param node TSNode
---@return integer|nil
local function determine_identifier_position(identifiers, node)
    for idx, identifier in pairs(identifiers) do
        if node == identifier then
            return idx
        end
    end
end

---@param identifiers TSNode[]
---@param bufnr integer
---@return TSNode|nil, integer|nil
local function get_node_to_inline(identifiers, bufnr)
    --- @type TSNode|nil, integer|nil
    local node_to_inline, identifier_pos

    if #identifiers == 1 then
        identifier_pos = 1
        node_to_inline = identifiers[identifier_pos]
    else
        node_to_inline, identifier_pos = get_select_input(
            identifiers,
            "123: Select an identifier to inline:",
            ---@param node TSNode
            ---@return string
            function(node)
                return vim.treesitter.get_node_text(node, bufnr)
            end
        )
    end

    return node_to_inline, identifier_pos
end

---@param identifiers TSNode[]
---@param values TSNode[]
---@param identifier_to_exclude TSNode[]
---@param bufnr integer
---@return string[] new_identifiers
---@return string[] new_values
local function construct_new_declaration(
    identifiers,
    values,
    identifier_to_exclude,
    bufnr
)
    local new_identifiers, new_values = {}, {}

    for idx, identifier in pairs(identifiers) do
        if identifier ~= identifier_to_exclude then
            table.insert(
                new_identifiers,
                vim.treesitter.get_node_text(identifier, bufnr)
            )
            table.insert(
                new_values,
                vim.treesitter.get_node_text(values[idx], bufnr)
            )
        end
    end

    return new_identifiers, new_values
end

---@param declarator_node TSNode
---@param identifiers TSNode[]
---@param node_to_inline TSNode
---@param refactor Refactor
---@param definition TSNode[]
---@param identifier_pos integer
---@return LspTextEdit[]
local function get_inline_text_edits(
    declarator_node,
    identifiers,
    node_to_inline,
    refactor,
    definition,
    identifier_pos
)
    local text_edits = {}

    local references =
        ts_locals.find_usages(definition, refactor.scope, refactor.bufnr)

    local all_values = refactor.ts:get_local_var_values(declarator_node)

    -- account for python giving multiple results for the values query
    if refactor.filetype == "python" then
        if #identifiers > 1 then
            all_values[#all_values] = nil
        else
            all_values = { all_values[#all_values] }
        end
    end

    local value_node_to_inline = all_values[identifier_pos]

    -- remove the whole declaration if there is only one identifier, else construct a new declaration
    if #identifiers == 1 then
        table.insert(
            text_edits,
            lsp_utils.delete_text(
                Region:from_node(declarator_node, refactor.bufnr)
            )
        )
    else
        local new_identifiers_text, new_values_text = construct_new_declaration(
            identifiers,
            all_values,
            node_to_inline,
            refactor.bufnr
        )

        table.insert(
            text_edits,
            lsp_utils.replace_text(
                Region:from_node(declarator_node, refactor.bufnr),
                refactor.code.constant({
                    multiple = true,
                    identifiers = new_identifiers_text,
                    values = new_values_text,
                })
            )
        )
    end

    local value_text =
        vim.treesitter.get_node_text(value_node_to_inline, refactor.bufnr)

    if
        refactor.filetype == "cpp"
        and value_node_to_inline:type() == "initializer_list"
    then
        -- HACK: The text contains the surrounding brackets. Since the parser does not
        -- expose a node that includes everything inside the brackets, we need
        -- to manually remove them.
        --
        -- {1} -> 1
        --
        -- https://github.com/ThePrimeagen/refactoring.nvim/issues/427
        value_text = value_text:sub(2, #value_text - 1)
    end

    for _, ref in pairs(references) do
        -- TODO: In my mind, if nothing is left on the line when you remove, it should get deleted.
        -- Could be done via opts into replace_text.

        local parent = assert(ref:parent()) ---@type TSNode
        if refactor.ts.should_check_parent_node(parent:type()) then
            ref = parent
        end

        refactor.success_message = ("[Refactor] Inlined %d variable occurences"):format(
            #references
        )

        table.insert(
            text_edits,
            lsp_utils.replace_text(Region:from_node(ref), value_text)
        )
    end
    return text_edits
end

---@param refactor Refactor
---@return boolean, Refactor|string
local function inline_var_setup(refactor)
    -- only deal with first declaration
    --- @type TSNode|nil
    local declarator_node = refactor.ts:local_declarations_in_region(
        refactor.scope,
        refactor.region
    )[1]

    if declarator_node == nil then
        -- if the visual selection does not contain a declaration and it only contains a reference
        -- (which is under the cursor)
        local identifier_node = vim.treesitter.get_node()
        if identifier_node == nil then
            return false, "Identifier_node is nil"
        end
        local definition =
            ts_locals.find_definition(identifier_node, refactor.bufnr)
        declarator_node =
            refactor.ts.get_container(definition, refactor.ts.variable_scope)

        if declarator_node == nil then
            return false, "Couldn't determine declarator node"
        end
    end

    local identifiers = refactor.ts:get_local_var_names(declarator_node)

    if #identifiers == 0 then
        return false, "No declarations in selected area"
    end

    local node_to_inline, identifier_pos =
        get_node_to_inline(identifiers, refactor.bufnr)

    if node_to_inline == nil or identifier_pos == nil then
        return false, "Couldn't determine node to inline"
    end

    local definition = ts_locals.find_definition(node_to_inline, refactor.bufnr)

    local text_edits = get_inline_text_edits(
        declarator_node,
        identifiers,
        node_to_inline,
        refactor,
        definition,
        identifier_pos
    )

    refactor.text_edits = text_edits
    return true, refactor
end

---@param refactor Refactor
local function inline_var_normal_setup(refactor)
    local declarator_node = refactor.region_node

    if declarator_node == nil then
        return false, "Couldn't determine declarator node"
    end

    local identifiers = refactor.ts:get_local_var_names(declarator_node)

    if #identifiers == 0 then
        return false, "No declarations in selected area"
    end

    local node_to_inline = refactor.identifier_node
    if node_to_inline == nil then
        return false, "There is no node on cursor"
    end
    if refactor.ts.should_check_parent_node(node_to_inline:type()) then
        --- @type TSNode?
        node_to_inline = node_to_inline:named_child(0)
        if node_to_inline == nil then
            return false, "There is no node on cursor"
        end
    end
    local definition = ts_locals.find_definition(node_to_inline, refactor.bufnr)
    local identifier_pos =
        determine_identifier_position(identifiers, definition)

    if identifier_pos == nil then
        return false, "Couldn't determine identifier position"
    end

    local text_edits = get_inline_text_edits(
        declarator_node,
        identifiers,
        node_to_inline,
        refactor,
        definition,
        identifier_pos
    )

    refactor.text_edits = text_edits
    return true, refactor
end

---@param bufnr integer
---@param opts Config
local function inline_var_visual(bufnr, opts)
    Pipeline:from_task(refactor_setup(bufnr, opts))
        :add_task(selection_setup)
        :add_task(inline_var_setup)
        :after(post_refactor.post_refactor)
        :run(nil, vim.notify)
end

-- bufnr integer
---@param opts Config
local function inline_var_normal(bufnr, opts)
    Pipeline:from_task(refactor_setup(bufnr, opts))
        :add_task(node_on_cursor_setup)
        :add_task(inline_var_normal_setup)
        :after(post_refactor.post_refactor)
        :run(nil, vim.notify)
end

---@param bufnr integer
---@param opts Config
function M.inline_var(bufnr, opts)
    local mode = vim.api.nvim_get_mode().mode
    if mode == "n" or mode == "c" then
        inline_var_normal(bufnr, opts)
    else
        inline_var_visual(bufnr, opts)
    end
end

return M
