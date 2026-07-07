(source_file) @scope.inside @scope

(func_literal
  body: (block
    (_)* @scope.inside)) @scope

(function_declaration
  parameters: (parameter_list) @scope
  body: (block
    (statement_list) @scope.inside) @scope)

(method_declaration
  parameters: (parameter_list) @scope
  body: (block
    (_)* @scope.inside) @scope)

(if_statement
  initializer: (_)? @scope
  condition: (_) @scope
  consequence: (block
    (statement_list) @scope.inside @scope))

(if_statement
  initializer: (_)? @scope
  condition: (_) @scope
  alternative: (block
    (statement_list) @scope.inside @scope))

(expression_switch_statement
  initializer: (_)? @scope
  value: (_) @scope
  (expression_case
    (statement_list) @scope.inside) @scope)

(expression_switch_statement
  initializer: (_)? @scope
  value: (_) @scope
  (default_case
    (statement_list) @scope.inside) @scope)

(for_statement
  body: (block
    (_)* @scope.inside)) @scope
