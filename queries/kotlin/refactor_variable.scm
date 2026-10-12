; NOTE: we don't support destructuring declarations (val (a, b) = pair) because
; the value is a single expression
; val a = 1
(property_declaration
  (variable_declaration
    (simple_identifier) @variable.identifier)
  .
  (_) @variable.value) @variable.declaration
