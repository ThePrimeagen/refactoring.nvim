(source_file
  (function_item) @input_function)

(mod_item
  body: (declaration_list
    (function_item) @input_function))

(impl_item
  body: (declaration_list
    (function_item) @input_function
    (#set! method)))
