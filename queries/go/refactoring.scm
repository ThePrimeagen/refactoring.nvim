;; Grabs all the local variable declarations.  This is useful for scope
;; variable passing.  Which variables do we need to pass to the extracted
;; function?
(short_var_declaration
 left: (expression_list
   (identifier) @definition.local_name)
 right: (expression_list
   (_) @definition.local_value)) @definition.local_declarator
(var_declaration
  (var_spec
    name: (identifier) @definition.local_name
    value: (expression_list
      (_) @definition.local_value))) @definition.local_declarator

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

(block) @definition.block

(short_var_declaration) @definition.statement
(return_statement) @definition.statement
(if_statement) @definition.statement
(for_statement) @definition.statement
(call_expression) @definition.statement

(method_declaration
   receiver: (parameter_list) @definition.class_name)
(method_declaration
   receiver: (parameter_list
   (parameter_declaration
   name: (identifier) @definition.class_type)))
