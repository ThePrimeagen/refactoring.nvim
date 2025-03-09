local Pipeline = require("refactoring.pipeline")
local Region = require("refactoring.region")
local tasks = require("refactoring.tasks")
local ui = require("refactoring.ui")
local notify = require("refactoring.notify")

local text_edits_utils = require("refactoring.text_edits_utils")

local ts_locals = require("refactoring.ts-locals")

local iter = vim.iter
local ts = vim.treesitter

local M = {}

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
        node_to_inline, identifier_pos = ui.select(
            identifiers,
            "123: Select an identifier to inline:",
            ---@param node TSNode
            ---@return string
            function(node)
                return ts.get_node_text(node, bufnr)
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
            table.insert(new_identifiers, ts.get_node_text(identifier, bufnr))
            table.insert(new_values, ts.get_node_text(values[idx], bufnr))
        end
    end

    return new_identifiers, new_values
end

---@param declarator_node TSNode
---@param identifiers TSNode[]
---@param node_to_inline TSNode
---@param refactor refactor.Refactor
---@param definition TSNode[]
---@param identifier_pos integer
---@return refactor.TextEdit[]
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
    references = iter(references):filter(refactor.ts.reference_filter):totable() --[=[@as TSNode[]]=]

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
            text_edits_utils.delete_text(
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
            text_edits_utils.replace_text(
                Region:from_node(declarator_node, refactor.bufnr),
                refactor.code.constant({
                    multiple = true,
                    identifiers = new_identifiers_text,
                    values = new_values_text,
                })
            )
        )
    end

    local value_text = ts.get_node_text(value_node_to_inline, refactor.bufnr)

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
        value_text = value_text:sub(2, #value_text - 1) ---@type string
    end

    for _, ref in pairs(references) do
        -- TODO: In my mind, if nothing is left on the line when you remove, it should get deleted.
        -- Could be done via opts into replace_text.

        if refactor.ts.should_check_parent_node(ref) then
            ref = assert(ref:parent())
        end

        refactor.success_message = ("Inlined %d variable occurrences"):format(
            #references
        )

        table.insert(
            text_edits,
            text_edits_utils.replace_text(Region:from_node(ref), value_text)
        )
    end
    return text_edits
end

---@param refactor refactor.Refactor
---@return boolean, refactor.Refactor|string
local function inline_var_setup(refactor)
    --- @type boolean
    local ok, declarator_nodes = pcall(
        refactor.ts.local_declarations_in_region,
        refactor.ts,
        refactor.scope,
        refactor.region
    )
    if not ok then
        return ok, declarator_nodes
    end
    -- only deal with first declaration
    local declarator_node = declarator_nodes[1] ---@type TSNode?

    if declarator_node == nil then
        -- if the selection does not contain a declaration and it only contains a reference
        -- (which is under the cursor)
        local identifier_node = ts.get_node()
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

    local ok2, identifiers =
        pcall(refactor.ts.get_local_var_names, refactor.ts, declarator_node)
    if not ok2 then
        return ok2, identifiers
    end

    if #identifiers == 0 then
        return false, "No declarations in selected area"
    end

    local node_to_inline, identifier_pos =
        get_node_to_inline(identifiers, refactor.bufnr)

    if node_to_inline == nil or identifier_pos == nil then
        return false, "Couldn't determine node to inline"
    end

    local definition = ts_locals.find_definition(node_to_inline, refactor.bufnr)

    local ok3, text_edits = pcall(
        get_inline_text_edits,
        declarator_node,
        identifiers,
        node_to_inline,
        refactor,
        definition,
        identifier_pos
    )
    if not ok3 then
        return ok3, identifiers
    end

    refactor.text_edits = text_edits
    return true, refactor
end

---@param bufnr integer
---@param region_type 'v' | 'V' | '' | nil
---@param opts refactor.Config
local function inline_var(bufnr, region_type, opts)
    local seed = tasks.refactor_seed(bufnr, region_type, opts)
    Pipeline:from_task(tasks.operator_setup)
        :add_task(inline_var_setup)
        :after(tasks.post_refactor)
        :run(nil, notify.error, seed)
end

---@param bufnr integer
---@param region_type 'v' | 'V' | '' | nil
---@param opts refactor.Config
function M.inline_var(bufnr, region_type, opts)
    inline_var(bufnr, region_type, opts)
end

return M
