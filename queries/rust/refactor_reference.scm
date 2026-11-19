; let a: i32 = 1;
; let mut a: i32;
(let_declaration
  pattern: (identifier) @reference.identifier
  type: (_) @_type
  (#set-type! rust @_type @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

; let a = 1;
(let_declaration
  pattern: (identifier) @reference.identifier
  !type
  value: (_) @_value
  (#infer-type! rust @_value)
  (#set! reference_type write)
  (#set! declaration))

; let (a, b) = (1, 2);
; let (a, (b, c)): (i32, (i32, i32)) = ...;
(let_declaration
  pattern: (tuple_pattern
    (identifier) @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

(let_declaration
  pattern: (tuple_pattern
    (tuple_pattern
      (identifier) @reference.identifier))
  (#set! reference_type write)
  (#set! declaration))

; let Foo { a, b } = foo;
(let_declaration
  pattern: (struct_pattern
    (field_pattern
      name: (shorthand_field_identifier) @reference.identifier))
  (#set! reference_type write)
  (#set! declaration))

(let_declaration
  pattern: (struct_pattern
    (field_pattern
      pattern: (identifier) @reference.identifier))
  (#set! reference_type write)
  (#set! declaration))

; fn f(a: i32, mut b: String)
(parameter
  pattern: (identifier) @reference.identifier
  type: (_) @_type
  (#set-type! rust @_type @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

; fn f(&self), fn f(&mut self), fn f(self)
((self_parameter
  (self) @reference.identifier) @_type
  (#set-type! rust @_type @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

; |a, b: i32| ...
(closure_parameters
  (identifier) @reference.identifier
  (#set! reference_type write)
  (#set! declaration))

(closure_parameters
  (parameter
    pattern: (identifier) @reference.identifier
    type: (_) @_type)
  (#set-type! rust @_type @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

; for a in xs { ... }
; for (a, b) in xs { ... }
(for_expression
  pattern: (identifier) @reference.identifier
  (#set! reference_type write)
  (#set! declaration))

(for_expression
  pattern: (tuple_pattern
    (identifier) @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

; if let Some(a) = b { ... }
; while let Ok(a) = b { ... }
; match x { Some(a) => ... }
(let_condition
  pattern: (identifier) @reference.identifier
  (#set! reference_type write)
  (#set! declaration))

; NOTE: identifiers starting with an uppercase letter (e.g. `None`) are enum
; variants or constants, not bindings
([
  (let_condition
    pattern: (tuple_struct_pattern
      (identifier) @reference.identifier))
  (match_pattern
    (tuple_struct_pattern
      (identifier) @reference.identifier))
  (match_pattern
    (identifier) @reference.identifier)
]
  (#lua-match? @reference.identifier "^[a-z_]")
  (#set! reference_type write)
  (#set! declaration))

; NOTE: methods (functions inside of `impl` blocks) are purposefully not
; included because they don't create an identifier in the scope
(source_file
  (function_item
    name: (identifier) @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

(block
  (function_item
    name: (identifier) @reference.identifier)
  (#set! reference_type write)
  (#set! declaration))

; a = 1;
; a += 1;
([
  (assignment_expression
    left: (identifier) @reference.identifier)
  (compound_assignment_expr
    left: (identifier) @reference.identifier)
]
  (#set! reference_type write))

([
  (assignment_expression
    left: [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
  (compound_assignment_expr
    left: [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
]
  (#set! reference_type write)
  (#set! field))

; *a = 1;
([
  (assignment_expression
    left: (unary_expression
      (identifier) @reference.identifier))
  (compound_assignment_expr
    left: (unary_expression
      (identifier) @reference.identifier))
]
  (#set! reference_type write))

([
  (assignment_expression
    right: (identifier) @reference.identifier)
  (compound_assignment_expr
    right: (identifier) @reference.identifier)
  (let_declaration
    value: (identifier) @reference.identifier)
  (binary_expression
    (identifier) @reference.identifier)
  (unary_expression
    (identifier) @reference.identifier)
  (reference_expression
    value: (identifier) @reference.identifier)
  (type_cast_expression
    value: (identifier) @reference.identifier)
  (try_expression
    (identifier) @reference.identifier)
  (await_expression
    (identifier) @reference.identifier)
  (parenthesized_expression
    (identifier) @reference.identifier)
  (tuple_expression
    (identifier) @reference.identifier)
  (array_expression
    (identifier) @reference.identifier)
  (range_expression
    (identifier) @reference.identifier)
  (arguments
    (identifier) @reference.identifier)
  ; a.b
  (field_expression
    value: (identifier) @reference.identifier)
  ; a[b]
  (index_expression
    (identifier) @reference.identifier)
  ; return a
  (return_expression
    (identifier) @reference.identifier)
  ; break a
  (break_expression
    (identifier) @reference.identifier)
  (if_expression
    condition: (identifier) @reference.identifier)
  (while_expression
    condition: (identifier) @reference.identifier)
  (let_condition
    value: (identifier) @reference.identifier)
  (for_expression
    value: (identifier) @reference.identifier)
  (match_expression
    value: (identifier) @reference.identifier)
  (match_arm
    value: (identifier) @reference.identifier)
  ; Foo { a: b }
  (field_initializer
    value: (identifier) @reference.identifier)
  ; Foo { a }
  (shorthand_field_initializer
    (identifier) @reference.identifier)
  ; ..a
  (base_field_initializer
    (identifier) @reference.identifier)
  ; trailing expression
  (block
    (identifier) @reference.identifier .)
  (closure_expression
    body: (identifier) @reference.identifier)
  ; println!("{}", a)
  (token_tree
    (identifier) @reference.identifier)
]
  (#set! reference_type read))

; self.a
([
  (field_expression
    value: (self) @reference.identifier)
  (arguments
    (self) @reference.identifier)
  (reference_expression
    value: (self) @reference.identifier)
  (token_tree
    (self) @reference.identifier)
  (block
    (self) @reference.identifier .)
  (return_expression
    (self) @reference.identifier)
]
  (#set! reference_type read))

([
  (binary_expression
    [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
  (unary_expression
    [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
  (reference_expression
    value: [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
  (arguments
    [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
  (let_declaration
    value: [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
  (assignment_expression
    right: [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
  (compound_assignment_expr
    right: [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
  (return_expression
    [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
  (field_expression
    value: [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
  (index_expression
    [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
  (if_expression
    condition: [
      (field_expression)
      (index_expression)
    ] @reference.identifier)
  (block
    [
      (field_expression)
      (index_expression)
    ] @reference.identifier .)
]
  (#set! reference_type read)
  (#set! field))

; f(a)
(call_expression
  function: (identifier) @reference.identifier
  (#set! reference_type read)
  (#set! function_call_identifier))

; a.f()
(call_expression
  function: (field_expression) @reference.identifier
  (#set! reference_type read)
  (#set! field)
  (#set! function_call_identifier))
