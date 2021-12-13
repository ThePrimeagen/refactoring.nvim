;; Grabs all the local variable declarations.  This is useful for scope
;; variable passing.  Which variables do we need to pass to the extracted
;; function?

; TODO: why did this stop working
((lexical_declaration
  (variable_declarator
    (identifier) @definition.local_name
    value: (_) @definition.local_value)))
; (lexical_declaration
    ; (variable_declarator
        ; name: ((identifier) @definition.local_name)))

; grabs all the arguments that are passed into the function. Needed for
; function extraction, 106.
(formal_parameters
    (identifier) @definition.function_argument)

; (program) @definition.block
; (statement_block) @definition.block

; (expression_statement) @definition.statement
; (return_statement) @definition.statement
; (if_statement) @definition.statement
; (for_statement) @definition.statement
; (do_statement) @definition.statement
; (while_statement) @definition.statement
; (lexical_declaration) @definition.statement

