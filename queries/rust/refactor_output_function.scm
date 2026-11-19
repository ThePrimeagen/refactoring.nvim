; NOTE: attributes (e.g. `#[test]`) are treated like comments so the extracted
; function is placed above them
(source_file
  _*
  [
    (line_comment)
    (block_comment)
    (attribute_item)
  ]* @output_function.comment
  .
  (function_item) @output_function)

(declaration_list
  _*
  [
    (line_comment)
    (block_comment)
    (attribute_item)
  ]* @output_function.comment
  .
  (function_item) @output_function)
