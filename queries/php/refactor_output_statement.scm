[
  (empty_statement)
  (compound_statement)
  (named_label_statement)
  (expression_statement)
  (switch_statement)
  (do_statement)
  (foreach_statement)
  (goto_statement)
  (continue_statement)
  (break_statement)
  (return_statement)
  (try_statement)
  (declare_statement)
  (echo_statement)
  (exit_statement)
  (unset_statement)
  (const_declaration)
  (class_declaration)
  (interface_declaration)
  (trait_declaration)
  (enum_declaration)
  (namespace_definition)
  (namespace_use_declaration)
  (global_declaration)
  (function_static_declaration)
] @output_statement

(if_statement
  body: (compound_statement
    (_) @output_statement.inside)) @output_statement

(for_statement
  body: (compound_statement
    (_) @output_statement.inside)) @output_statement

(while_statement
  body: (compound_statement
    (_) @output_statement.inside)) @output_statement

(method_declaration
  body: (compound_statement
    (_) @output_statement.inside)) @output_statement

(function_definition
  body: (compound_statement
    (_) @output_statement.inside)) @output_statement
