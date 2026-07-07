(_
  (block
    (_)* @scope.inside) @_block
  (#not-has-parent? @_block method_declaration)) @scope

(method_declaration
  parameters: (_) @scope
  body: (block
    (_)* @scope.inside) @scope)

; NOTE: records have parameters, and we are assuming that each variable
; declaration has a scope, so this must be their scope (even though they don't
; have a tradicional `block`)
(record_declaration) @scope.inside @scope

(class_declaration
  body: (class_body
    (_)* @scope.inside)) @scope
