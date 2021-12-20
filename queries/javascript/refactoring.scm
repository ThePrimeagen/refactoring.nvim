;; Grabs all the local variable declarations.  This is useful for scope
;; variable passing.  Which variables do we need to pass to the extracted
;; function?

; TODO: why did this stop working
((lexical_declaration
  (variable_declarator
    (identifier) @definition.local_name)))

; grabs all the arguments that are passed into the function. Needed for
; function extraction, 106.
(formal_parameters
    (identifier) @definition.function_argument)
