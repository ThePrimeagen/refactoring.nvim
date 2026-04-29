local function foo()
  -- __PRINT_LOC_START
  print([==[┆foo┆ ┊1┊]==])-- __PRINT_LOC_END
  print('foo')
  -- __PRINT_LOC_START
  print([==[┆foo┆ ┊2┊]==])-- __PRINT_LOC_END
end
foo()
