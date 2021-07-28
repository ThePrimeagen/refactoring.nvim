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
    (identifier) @definition.function_argument)?
  (optional_parameter
   (identifier) @definition.function_argument?)))

(program) @definition.scope
(function_declaration) @definition.scope
(lexical_declaration) @definition.scope
