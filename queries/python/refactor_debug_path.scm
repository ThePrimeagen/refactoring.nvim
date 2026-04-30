((if_statement
  (#set! text if)) @debug_path_segment
  (#offset! @debug_path_segment 0 -1 0 1))

((for_statement
  (#set! text for)) @debug_path_segment
  (#offset! @debug_path_segment 0 -1 0 1))

((while_statement
  (#set! text while)) @debug_path_segment
  (#offset! @debug_path_segment 0 -1 0 1))

((function_definition
  name: (_) @_name
  (#set! text @_name)) @debug_path_segment
  (#offset! @debug_path_segment 0 -1 0 1))
