[
  (attributed_statement)
  (break_statement)
  (case_statement)
  (continue_statement)
  (expression_statement)
  (goto_statement)
  (labeled_statement)
  (return_statement)
  (seh_leave_statement)
  (seh_try_statement)
  (switch_statement)
  (declaration)
] @output_statement

(if_statement
  consequence: (compound_statement
    .
    (_) @output_statement.inside)) @output_statement

(do_statement
  body: (compound_statement
    .
    (_) @output_statement.inside)) @output_statement

(while_statement
  body: (compound_statement
    .
    (_) @output_statement.inside)) @output_statement

(for_statement
  body: (compound_statement
    .
    (_) @output_statement.inside)) @output_statement

(function_definition
  body: (compound_statement
    .
    (_) @output_statement.inside)) @output_statement
