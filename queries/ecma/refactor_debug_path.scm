(if_statement
  (#set! text if)) @debug_path_segment

(while_statement
  (#set! text while)) @debug_path_segment

(do_statement
  (#set! text do)) @debug_path_segment

(for_statement
  (#set! text for)) @debug_path_segment

(function_declaration
  name: (_) @_name
  (#set! text @_name)) @debug_path_segment

; let a = () => {}
(_
  (variable_declarator
    name: (identifier) @_name
    value: (arrow_function))
  (#set! text @_name)) @debug_path_segment

; a = () => {}
(assignment_expression
  left: (_) @_name
  right: (arrow_function)
  (#set! text @_name)) @debug_path_segment

; const something = { a: () => {} }
(pair
  key: (_) @_name
  value: (arrow_function)
  (#set! text @_name)) @debug_path_segment

; [1, 2 , 3].reduce((a, b) => a + b)
(arrow_function
  (#not-has-parent? @debug_path_segment assignment_expression variable_declarator pair)
  (#set! text "(anon)")) @debug_path_segment
