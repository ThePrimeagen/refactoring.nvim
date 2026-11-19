; NOTE: control flow expressions are handled below because they have an
; `@output_statement.inside`
(block
  [
    (let_declaration)
    (empty_statement)
    (const_item)
    (static_item)
    (use_declaration)
    (struct_item)
    (enum_item)
    (type_item)
    (impl_item)
    (trait_item)
    (mod_item)
    (macro_definition)
    (expression_statement
      [
        (array_expression)
        (assignment_expression)
        (async_block)
        (await_expression)
        (binary_expression)
        (block)
        (break_expression)
        (call_expression)
        (closure_expression)
        (compound_assignment_expr)
        (const_block)
        (continue_expression)
        (field_expression)
        (generic_function)
        (identifier)
        (index_expression)
        (macro_invocation)
        (match_expression)
        (parenthesized_expression)
        (reference_expression)
        (return_expression)
        (scoped_identifier)
        (self)
        (struct_expression)
        (try_block)
        (try_expression)
        (tuple_expression)
        (type_cast_expression)
        (unary_expression)
        (unit_expression)
        (unsafe_block)
        (yield_expression)
      ])
    ; trailing expression (block's value)
    (array_expression)
    (await_expression)
    (binary_expression)
    (call_expression)
    (field_expression)
    (identifier)
    (index_expression)
    (macro_invocation)
    (match_expression)
    (parenthesized_expression)
    (reference_expression)
    (scoped_identifier)
    (self)
    (struct_expression)
    (try_expression)
    (tuple_expression)
    (type_cast_expression)
    (unary_expression)
    (unit_expression)
    (boolean_literal)
    (char_literal)
    (float_literal)
    (integer_literal)
    (string_literal)
    (raw_string_literal)
  ] @output_statement)

(block
  (expression_statement
    (if_expression
      consequence: (block
        .
        (_)? @output_statement.inside))) @output_statement)

(block
  (expression_statement
    (for_expression
      body: (block
        .
        (_)? @output_statement.inside))) @output_statement)

(block
  (expression_statement
    (while_expression
      body: (block
        .
        (_)? @output_statement.inside))) @output_statement)

(block
  (expression_statement
    (loop_expression
      body: (block
        .
        (_)? @output_statement.inside))) @output_statement)

(block
  (function_item
    body: (block
      .
      (_)? @output_statement.inside)) @output_statement)

; fn f() { ... } at top level, inside of `impl`, `mod`, etc.
((function_item
  body: (block
    .
    (_)? @output_statement.inside)) @output_statement
  (#not-has-parent? @output_statement block)
  (#set! inside_only))
