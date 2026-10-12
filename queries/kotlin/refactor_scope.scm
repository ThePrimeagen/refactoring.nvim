(function_declaration
  (function_value_parameters) @scope
  (function_body
    (statements) @scope.inside) @scope)

; if (a) { ... }
; for (a in xs) { ... }
(control_structure_body
  (statements) @scope.inside) @scope

(lambda_literal
  (statements) @scope.inside) @scope

(class_body
  (_)* @scope.inside) @scope

(source_file
  (_)* @scope.inside) @scope
