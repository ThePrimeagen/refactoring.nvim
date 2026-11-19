; NOTE: we don't support destructuring declarations (let (a, b) = pair;)
; because the value is a single expression
; let a = 1;
(let_declaration
  pattern: (identifier) @variable.identifier
  value: (_) @variable.value) @variable.declaration
