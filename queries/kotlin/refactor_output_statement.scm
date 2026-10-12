(statements
  [
    (additive_expression)
    (annotation)
    (anonymous_function)
    (as_expression)
    (assignment)
    (bin_literal)
    (boolean_literal)
    (call_expression)
    (callable_reference)
    (character_literal)
    (check_expression)
    (class_declaration)
    (collection_literal)
    (comparison_expression)
    (conjunction_expression)
    (destructuring_declaration)
    (disjunction_expression)
    (elvis_expression)
    (equality_expression)
    (getter)
    (hex_literal)
    (indexing_expression)
    (infix_expression)
    (integer_literal)
    (jump_expression)
    (lambda_literal)
    (long_literal)
    (multiplicative_expression)
    (navigation_expression)
    (null_literal)
    (object_declaration)
    (object_literal)
    (parenthesized_expression)
    (postfix_expression)
    (prefix_expression)
    (property_declaration)
    (range_expression)
    (real_literal)
    (setter)
    (simple_identifier)
    (spread_expression)
    (string_literal)
    (super_expression)
    (this_expression)
    (try_expression)
    (type_alias)
    (unsigned_literal)
    (when_expression)
  ] @output_statement)

(statements
  (for_statement
    (control_structure_body
      (statements)? @output_statement.inside)) @output_statement)

(statements
  ((label)
    .
    (for_statement
      (control_structure_body
        (statements)? @output_statement.inside))) @output_statement)

(statements
  (while_statement
    (control_structure_body
      (statements)? @output_statement.inside)) @output_statement)

(statements
  ((label)
    .
    (while_statement
      (control_structure_body
        (statements)? @output_statement.inside))) @output_statement)

(statements
  (do_while_statement
    (control_structure_body
      (statements)? @output_statement.inside)) @output_statement)

(statements
  ((label)
    .
    (do_while_statement
      (control_structure_body
        (statements)? @output_statement.inside))) @output_statement)

(statements
  (if_expression
    consequence: (control_structure_body
      (statements)? @output_statement.inside)) @output_statement)

(statements
  (function_declaration
    (function_body
      (statements)? @output_statement.inside)) @output_statement)

; fun f() { ... }, `class A { fun f() { ... } }`
((function_declaration
  (function_body
    (statements) @output_statement.inside)) @output_statement
  (#not-has-parent? @output_statement statements)
  (#set! inside_only))

; { a -> ... }
(lambda_literal
  (statements) @output_statement.inside
  (#set! inside_only)) @output_statement
