;; Grabs all the local variable declarations. This is useful for scope
;; variable passing.  Which variables do we need to pass to the extracted
;; function?
(declaration
  declarator: (init_declarator
    declarator: (_) @definition.local_name
    value: (_) @definition.local_value)) @definition.local_declaration

;; grabs all the arguments that are passed into the function. Needed for
;; function extraction, 106.
((parameter_list
    (parameter_declaration
        declarator: (_) @definition.function_argument)))

(function_definition) @definition.block
(compound_statement) @definition.block
