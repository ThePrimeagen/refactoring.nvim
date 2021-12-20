;; Grabs all the local variable declarations.  This is useful for scope
;; variable passing.  Which variables do we need to pass to the extracted
;; function?
(short_var_declaration
 left: (expression_list
   (identifier) @definition.local_name))
(var_declaration
  (var_spec
    name: (identifier) @definition.local_name))

;; grabs all the arguments that are passed into the function.  Needed for
;; function extraction, 106
(function_declaration
   parameters: (parameter_list
   (parameter_declaration
   (identifier) @definition.function_argument)))
(method_declaration
   parameters: (parameter_list
   (parameter_declaration
   name: (identifier) @definition.function_argument)))
