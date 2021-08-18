;; Grabs all the local variable declarations.  This is useful for scope
;; variable passing.  Which variables do we need to pass to the extracted
;; function?
((short_var_declaration
 (expression_list
   (identifier) @definition.local_name)))
((var_declaration
 (var_spec
   (identifier) @definition.local_name)))

;; grabs all the arguments that are passed into the function.  Needed for
;; function extraction, 106
(function_declaration
   parameters: (parameter_list
   (parameter_declaration
   (identifier) @definition.function_argument)))

;; TODO is this scope required? Fails when this is uncommented
;; (program) @definition.scope
(function_declaration) @definition.scope

(block) @definition.block

(short_var_declaration) @definition.statement
(return_statement) @definition.statement
(if_statement) @definition.statement
(for_statement) @definition.statement
(call_expression) @definition.statement
