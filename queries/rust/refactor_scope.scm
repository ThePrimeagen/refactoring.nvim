(source_file
  (_)* @scope.inside) @scope

(function_item
  parameters: (parameters) @scope
  body: (block
    (_)* @scope.inside) @scope)

; |a| a + 1
; |a| { ... }
(closure_expression
  parameters: (closure_parameters) @scope
  body: (_) @scope.inside @scope)

; for a in xs { ... }
(for_expression
  pattern: (_) @scope
  body: (block
    (_)* @scope.inside) @scope)

; if a { ... }
; if let Some(a) = b { ... }
(if_expression
  condition: (_) @scope
  consequence: (block
    (_)* @scope.inside) @scope)

; while a { ... }
; while let Some(a) = b { ... }
(while_expression
  condition: (_) @scope
  body: (block
    (_)* @scope.inside) @scope)

; else { ... }, loop { ... }, unsafe { ... }, { ... }
((block
  (_)* @scope.inside) @scope
  (#not-has-parent? @scope function_item closure_expression for_expression if_expression while_expression))

[
  (impl_item
    body: (declaration_list
      (_)* @scope.inside))
  (trait_item
    body: (declaration_list
      (_)* @scope.inside))
  (mod_item
    body: (declaration_list
      (_)* @scope.inside))
] @scope
