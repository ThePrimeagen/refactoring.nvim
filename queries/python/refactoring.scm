;; Grabs all the local variable declarations.  This is useful for scope
;; variable passing.  Which variables do we need to pass to the extracted
;; function?
((expression_statement
  (assignment
    (identifier) @definition.local_name)))

;; grabs all the arguments that are passed into the function.  Needed for
;; function extraction, 106
((function_definition
  (parameters
    (identifier)@definition.function_argument)))

;; Scope
(function_definition) @definition.scope
(module) @definition.scope
