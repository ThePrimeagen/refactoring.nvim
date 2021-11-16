;; Grabs all the local variable declarations.  This is useful for scope
;; variable passing.  Which variables do we need to pass to the extracted
;; function?
(assignment
	(identifier) @definition.local_name)

;; support keyword method params
(method
  (method_parameters
    (keyword_parameter
    (identifier) @definition.function_argument)))

;; support non-keyword method params
(method
  (method_parameters
    (identifier) @definition.function_argument))

;; matches a in:
;; my_array.each do |a|
;;   puts a
;; end
(do_block
	(block_parameters
	(identifier) @definition.function_argument))

;; matches my_array in:
;; my_array.each do |a|
;;   puts a
;; end
(method
	(call
		receiver: (identifier) @definition.function_argument))

;; matches 1,2,3 in:
;; [1,2,3].each do |a|
;;   puts a
;; end
(method
	(call
		receiver: (array
		(identifier) @definition.function_argument)))

;; Scope
(method) @definition.scope
(class) @definition.scope

;; Blocks
(do_block) @definition.block
(block) @definition.block

;; Statements
(if) @definition.statement
(for) @definition.statement
(while) @definition.statement
