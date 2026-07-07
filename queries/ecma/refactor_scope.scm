(do_statement
  body: (statement_block
    (_)* @scope.inside)) @scope

(while_statement
  body: (statement_block
    (_)* @scope.inside)) @scope

(catch_clause
  body: (statement_block
    (_)* @scope.inside)) @scope

(for_in_statement
  body: (statement_block
    (_)* @scope.inside)) @scope

(for_statement
  body: (statement_block
    (_)* @scope.inside)) @scope

(function_declaration
  parameters: (_) @scope
  body: (statement_block
    (_)* @scope.inside) @scope)

(class_declaration
  (class_body
    (method_definition
      parameters: (_) @scope
      body: (statement_block
        (_)* @scope.inside) @scope)))

(function_expression
  body: (statement_block
    (_)* @scope.inside)) @scope

(program)* @scope.inside @scope

(arrow_function
  body: (statement_block
    (_)* @scope.inside)) @scope

(if_statement
  consequence: (statement_block) @scope @scope.inside)

(if_statement
  alternative: (else_clause
    (statement_block) @scope @scope.inside))

(class_declaration
  body: (class_body
    (_)* @scope.inside)) @scope
