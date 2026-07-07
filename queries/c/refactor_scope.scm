(struct_specifier) @scope @scope.inside

(function_definition
  declarator: (function_declarator
    parameters: (parameter_list) @scope)
  body: (compound_statement
    (_)* @scope.inside) @scope)

(translation_unit) @scope @scope.inside

(while_statement
  body: (compound_statement
    (_)* @scope.inside)) @scope

(for_statement
  body: (compound_statement
    (_)* @scope.inside)) @scope

(if_statement
  consequence: (_) @scope @scope.inside)

(if_statement
  alternative: (else_clause
    (_) @scope @scope.inside))
