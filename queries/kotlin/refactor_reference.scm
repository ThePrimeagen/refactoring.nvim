; val a: Int = 1
; var a = 1
(property_declaration
  (variable_declaration
    (simple_identifier) @reference.identifier
    (_)? @_type)
  (#set-type! kotlin @_type @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

(parameter
  (simple_identifier) @reference.identifier
  (_) @_type
  (#set-type! kotlin @_type @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

(for_statement
  (variable_declaration
    (simple_identifier) @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

(lambda_parameters
  (variable_declaration
    (simple_identifier) @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

; a = 1
; a += 1
(assignment
  (directly_assignable_expression
    (simple_identifier) @reference.identifier)
  (#set! reference_type write))

((prefix_expression
  [
    "++"
    "--"
  ]
  (simple_identifier) @reference.identifier)
  (#set! reference_type write))

((postfix_expression
  (simple_identifier) @reference.identifier
  [
    "++"
    "--"
  ])
  (#set! reference_type write))

([
  (additive_expression
    (simple_identifier) @reference.identifier)
  (multiplicative_expression
    (simple_identifier) @reference.identifier)
  (comparison_expression
    (simple_identifier) @reference.identifier)
  (equality_expression
    (simple_identifier) @reference.identifier)
  ; a && b
  (conjunction_expression
    (simple_identifier) @reference.identifier)
  ; a || b
  (disjunction_expression
    (simple_identifier) @reference.identifier)
  ; a ?: b
  (elvis_expression
    (simple_identifier) @reference.identifier)
  ; a..b
  (range_expression
    (simple_identifier) @reference.identifier)
  (prefix_expression
    [
      "-"
      "+"
      "!"
    ]
    (simple_identifier) @reference.identifier)
  (postfix_expression
    (simple_identifier) @reference.identifier
    "!!")
  (as_expression
    (simple_identifier) @reference.identifier)
  ; a is T
  ; a in xs
  (check_expression
    (simple_identifier) @reference.identifier)
  ; f(*a)
  (spread_expression
    (simple_identifier) @reference.identifier)
  (parenthesized_expression
    (simple_identifier) @reference.identifier)
  ; a.b
  (navigation_expression
    (simple_identifier) @reference.identifier)
  ; a[i]
  (indexing_expression
    (simple_identifier) @reference.identifier)
  ; xs[a]
  (indexing_suffix
    (simple_identifier) @reference.identifier)
  ; [a]
  (collection_literal
    (simple_identifier) @reference.identifier)
  ; "${a}"
  (interpolated_expression
    (simple_identifier) @reference.identifier)
  ; return a
  ; throw a
  (jump_expression
    (simple_identifier) @reference.identifier)
  (if_expression
    (simple_identifier) @reference.identifier)
  ; when (a) { ... }
  (when_subject
    (simple_identifier) @reference.identifier)
  ; when (x) { a -> ... }
  (when_condition
    (simple_identifier) @reference.identifier)
  ; when (x) { in a -> ... }
  (range_test
    (simple_identifier) @reference.identifier)
  ; when (x) { is T if a -> ... }
  (guard_condition
    (simple_identifier) @reference.identifier)
  (while_statement
    (simple_identifier) @reference.identifier)
  (do_while_statement
    (simple_identifier) @reference.identifier)
  (for_statement
    (simple_identifier) @reference.identifier)
  ; if (c) a else b
  (control_structure_body
    (simple_identifier) @reference.identifier)
  (statements
    (simple_identifier) @reference.identifier)
  (function_body
    (simple_identifier) @reference.identifier)
  (property_declaration
    (simple_identifier) @reference.identifier)
  ; val x by a
  (property_delegate
    (simple_identifier) @reference.identifier)
  ; class C(a: I) : I by a
  (explicit_delegation
    (simple_identifier) @reference.identifier)
  (assignment
    (simple_identifier) @reference.identifier)
]
  (#set! reference_type read))

; f(a)
; f(x = a)
((value_argument
  (simple_identifier) @reference.identifier .)
  (#set! reference_type read))

; a to b
([
  (infix_expression
    .
    (simple_identifier) @reference.identifier)
  (infix_expression
    (simple_identifier) @reference.identifier .)
]
  (#set! reference_type read))

; "$a"
((interpolated_identifier) @reference.identifier
  (#set! reference_type read))
