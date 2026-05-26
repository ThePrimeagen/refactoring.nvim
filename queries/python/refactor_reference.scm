(typed_parameter
  (identifier) @reference.identifier
  type: (_) @_type
  (#set-type! python @_type @reference.identifier)
  (#set! declaration))

(parameters
  (identifier) @reference.identifier
  (#set! declaration))

(assignment
  left: (identifier) @reference.identifier
  (#set! reference_type write)
  (#set! declaration))

(assignment
  right: (identifier) @reference.identifier
  (#set! reference_type read))

; [foo, bar] = ... / (foo, bar) = ...
(assignment
  left: (_
    (identifier) @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

(binary_operator
  (identifier) @reference.identifier
  (#set! reference_type read))

(comparison_operator
  (identifier) @reference.identifier
  (#set! reference_type read))

(for_statement
  left: (identifier) @reference.identifier
  (#set! reference_type write)
  (#set! declaration))

(for_statement
  right: (identifier) @reference.identifier
  (#set! reference_type read))

(while_statement
  condition: (identifier) @reference.identifier
  (#set! reference_type read))

(if_statement
  condition: (identifier) @reference.identifier
  (#set! reference_type read))

(argument_list
  (identifier) @reference.identifier
  (#set! reference_type read))

(keyword_argument
  value: (identifier) @reference.identifier
  (#set! reference_type read))

(augmented_assignment
  left: (identifier) @reference.identifier
  (#set! reference_type write)
  (#set! declaration))

(augmented_assignment
  right: (identifier) @reference.identifier
  (#set! reference_type read))

(return_statement
  (identifier) @reference.identifier
  (#set! reference_type read))

(subscript
  value: (identifier) @reference.identifier
  (#set! reference_type read))

(attribute
  object: (identifier) @reference.identifier
  (#set! reference_type read))

(call
  function: (identifier) @reference.identifier
  (#set! reference_type read)
  (#set! function_call_identifier))

(function_definition
  name: (_) @reference.identifier
  (#set! reference_type write)
  (#set! declaration))
