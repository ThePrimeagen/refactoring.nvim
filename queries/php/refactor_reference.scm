; TODO: because PHP doesn't have a proper declaration statement, each
; assignment is currently interpreted as a declaration, which can lead to
; unexpected behaviour
; $foo = 'foo'
(assignment_expression
  left: (variable_name) @reference.identifier
  right: (_) @_value
  (#infer-type! php @_value)
  (#set! reference_type write)
  (#set! declaration))

; [$foo, $bar] = ...
(assignment_expression
  left: (list_literal
    .
    (variable_name) @reference.identifier
    (","
      .
      (variable_name) @reference.identifier)*)
  (#set! reference_type write)
  (#set! declaration))

; [$foo, $bar] = ['foo', 'bar']
(assignment_expression
  left: (list_literal
    .
    (variable_name) @reference.identifier
    (","
      .
      (variable_name) @reference.identifier)*)
  right: (array_creation_expression
    .
    (array_element_initializer
      (_) @_value)
    .
    (","
      .
      (array_element_initializer
        (_) @_value)))
  (#infer-type! php @_value)
  (#set! reference_type write)
  (#set! declaration))

; $i;
(expression_statement
  (variable_name) @reference.identifier
  (#set! declaration))

(simple_parameter
  type: (_) @_type
  name: (variable_name) @reference.identifier
  (#set-type! php @_type @reference.identifier)
  (#set! declaration))

(binary_expression
  (variable_name) @reference.identifier
  (#set! reference_type read))

(update_expression
  (variable_name) @reference.identifier
  (#set! reference_type write))

(augmented_assignment_expression
  left: (variable_name) @reference.identifier
  (#set! reference_type write))

(augmented_assignment_expression
  right: (variable_name) @reference.identifier
  (#set! reference_type read))

(arguments
  (argument
    (variable_name) @reference.identifier)
  (#set! reference_type read))

(print_intrinsic
  (variable_name) @reference.identifier
  (#set! reference_type read))

(return_statement
  (variable_name) @reference.identifier
  (#set! reference_type read))

(echo_statement
  (variable_name) @reference.identifier
  (#set! reference_type read))

(sequence_expression
  (variable_name) @reference.identifier
  (#set! reference_type read))

(parenthesized_expression
  (variable_name) @reference.identifier
  (#set! reference_type read))

(subscript_expression
  (variable_name) @reference.identifier
  (#set! reference_type read))

(member_access_expression
  (variable_name) @reference.identifier
  (#set! reference_type read))

(member_call_expression
  (variable_name) @reference.identifier
  (#set! reference_type read)
  (#set! function_call_identifier))

(function_call_expression
  function: (variable_name) @reference.identifier
  (#set! reference_type read)
  (#set! function_call_identifier))

(function_definition
  name: (_) @reference.identifier
  (#set! reference_type write)
  (#set! declaration))

(function_definition
  parameters: (formal_parameters
    (simple_parameter
      name: (variable_name) @reference.identifier))
  (#set! reference_type write)
  (#set! declaration))

((encapsed_string
  (variable_name) @reference.identifier)
  (#set! reference_type read))
