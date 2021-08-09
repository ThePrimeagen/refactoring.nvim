;; Grabs all the local variable declarations.  This is useful for scope
;; variable passing.  Which variables do we need to pass to the extracted
;; function?
((lexical_declaration
  (variable_declarator
    (identifier) @definition.local_var)))

;; grabs all the arguments that are passed into the function. Needed for
;; function extraction, 106.
((formal_parameters
  (required_parameter
    (identifier) @definition.function_argument)))
((formal_parameters
  (optional_parameter
    (identifier) @definition.function_argument)))

(program) @definition.scope
(function_declaration) @definition.scope
(arrow_function) @definition.scope

(expression_statement) @definition.statement
(return_statement) @definition.statement
(if_statement) @definition.statement
(for_statement) @definition.statement
(do_statement) @definition.statement
(while_statement) @definition.statement
(lexical_declaration) @definition.statement
