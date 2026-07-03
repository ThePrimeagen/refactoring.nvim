;inherits: ecma

; let foo
(variable_declarator
  name: (identifier) @reference.identifier
  (#set! reference_type write)
  (#set! declaration))

; let foo = 1
(variable_declarator
  name: (identifier) @reference.identifier
  value: (_) @_value
  (#infer-type! javascript @_value)
  (#set! reference_type write)
  (#set! declaration))

(formal_parameters
  (identifier) @reference.identifier
  (#set! reference_type write)
  (#set! declaration))

(field_definition
  (property_identifier) @reference.identifier
  (#set! declaration)
  (#set! reference_type write))

(jsx_expression
  (identifier) @reference.identifier
  (#set! reference_type read))
