-- Some other suggestions
-- You should remove lsp_utils and change it to: text_edits.*
--  this will make it much less confusing. It's not really about LSP,
--  it's just about using one of the data structures.
local Pipeline = require("refactoring.pipeline")
local Region = require("refactoring.region")
local post_refactor = require("refactoring.tasks.post_refactor")
local refactor_setup = require("refactoring.tasks.refactor_setup")
local selection_setup = require("refactoring.tasks.selection_setup")
local get_select_input = require("refactoring.get_select_input")

local lsp_utils = require("refactoring.lsp_utils")

local ts = require("refactoring.ts")

local M = {}

local function get_inline_setup_pipeline(bufnr, opts)
    return Pipeline
        :from_task(refactor_setup(bufnr, opts))
        :add_task(selection_setup)
end

local function determine_declarator_node(refactor, bufnr)
    -- only deal with first declaration
    local declarator_node = refactor.ts:local_declarations_in_region(
        refactor.scope,
        refactor.region
    )[1]

    if declarator_node then
        return declarator_node, false
    else
        local current_node = ts.get_node_at_cursor(0)
        local definition = ts.find_definition(current_node, bufnr)
        declarator_node = refactor.ts.get_container(
            definition,
            refactor.ts.variable_scope
        )
        return declarator_node, true
    end
end

local function determine_identifier_position(identifiers, node)
    for idx, identifier in pairs(identifiers) do
        if node == identifier then
            return idx
        end
    end
end

local function get_node_to_inline(identifiers, bufnr)
    local node_to_inline, identifier_pos

    if #identifiers == 0 then
        error("No declarations in selected area")
    elseif #identifiers == 1 then
        identifier_pos = 1
    else
        node_to_inline, identifier_pos = get_select_input(
            identifiers,
            "123: Select an identifier to inline:",
            function(node)
                return ts.get_node_text(node, bufnr)
            end
        )
    end

    return node_to_inline, identifier_pos
end

function M.inline_var(bufnr, opts)
    get_inline_setup_pipeline(bufnr, opts)
        :add_task(function(refactor)
            -- figure out if we're dealing with a visual selection or a cursor node
            local declarator_node, node_on_cursor = determine_declarator_node(
                refactor,
                bufnr
            )

            -- get all identifiers in the declarator node (for either situation)
            local identifiers = refactor.ts:get_local_var_names(declarator_node)

            -- these three vars are determined based on the situation
            local node_to_inline, identifier_pos, definition

            if node_on_cursor then
                node_to_inline = ts.get_node_at_cursor(0)
                definition = ts.find_definition(node_to_inline, bufnr)
                identifier_pos = determine_identifier_position(
                    identifiers,
                    definition
                )
            else
                node_to_inline, identifier_pos = get_node_to_inline(
                    identifiers,
                    bufnr
                )
                definition = ts.find_definition(node_to_inline, bufnr)
            end

            local references = ts.find_references(
                definition,
                nil,
                bufnr,
                definition
            )

            local value_node =
                refactor.ts:get_local_var_values(
                    declarator_node
                )[identifier_pos]

            local text_edits = {}

            -- only _emove declarator node if there is one declaration
            if #identifiers == 1 then
                table.insert(
                    text_edits,
                    lsp_utils.delete_text(
                        Region:from_node(declarator_node, bufnr)
                    )
                )
            else
                -- TODO: there has to be a better way for this to look good
                print(" ")
                print(
                    "123: Removing initial variable declaration on multi-declaration statments is not yet supported. Please remove the inlined variable manually."
                )
            end

            local value_text = ts.get_node_text(value_node, bufnr)

            for _, ref in pairs(references) do
                -- TODO: In my mind, if nothing is left on the line when you remove, it should get deleted.
                -- Could be done via opts into replace_text.
                local insert_text, delete_text = lsp_utils.replace_text(
                    Region:from_node(ref),
                    value_text
                )

                table.insert(text_edits, insert_text)
                table.insert(text_edits, delete_text)
            end

            refactor.text_edits = text_edits
            return true, refactor
        end)
        :after(post_refactor)
        :run()
end

return M
