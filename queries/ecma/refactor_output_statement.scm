[
  (break_statement)
  (continue_statement)
  (debugger_statement)
  (lexical_declaration)
  (variable_declaration)
  (export_statement)
  (expression_statement)
  (import_statement)
  (labeled_statement)
  (return_statement)
  (switch_statement)
  (throw_statement)
  (try_statement)
  (with_statement)
] @output_statement

(arrow_function
  body: (statement_block
    .
    (_) @output_statement.inside)
  (#set! inside_only)) @output_statement

(do_statement
  body: (statement_block
    .
    (_) @output_statement.inside)) @output_statement

(while_statement
  body: (statement_block
    .
    (_) @output_statement.inside)) @output_statement

(catch_clause
  body: (statement_block
    .
    (_) @output_statement.inside)) @output_statement

(for_in_statement
  body: (statement_block
    .
    (_) @output_statement.inside)) @output_statement

(for_statement
  body: (statement_block
    .
    (_) @output_statement.inside)) @output_statement

(function_declaration
  body: (statement_block
    .
    (_) @output_statement.inside)) @output_statement

(class_declaration
  (class_body
    (method_definition
      body: (statement_block
        .
        (_) @output_statement.inside) @output_statement)))

(function_expression
  body: (statement_block
    .
    (_) @output_statement.inside)) @output_statement

(if_statement
  consequence: (statement_block
    .
    (_) @output_statement.inside)) @output_statement

(if_statement
  alternative: (else_clause
    (statement_block
      .
      (_) @output_statement.inside)) @output_statement)

; any statement except `statement_block`
(if_statement
  consequence: [
    (break_statement)
    (continue_statement)
    (debugger_statement)
    (declaration)
    (do_statement)
    (empty_statement)
    (export_statement)
    (expression_statement)
    (for_in_statement)
    (for_statement)
    (if_statement)
    (import_statement)
    (labeled_statement)
    (return_statement)
    (switch_statement)
    (throw_statement)
    (try_statement)
    (while_statement)
    (with_statement)
  ]) @output_statement

(if_statement
  alternative: (else_clause
    [
      (break_statement)
      (continue_statement)
      (debugger_statement)
      (declaration)
      (do_statement)
      (empty_statement)
      (export_statement)
      (expression_statement)
      (for_in_statement)
      (for_statement)
      (if_statement)
      (import_statement)
      (labeled_statement)
      (return_statement)
      (switch_statement)
      (throw_statement)
      (try_statement)
      (while_statement)
      (with_statement)
    ])) @output_statement

(class_declaration
  body: (class_body
    (_) @output_statement.inside)) @output_statement
