local function print_foo(foo)
  print(foo)
  return foo
end

local foo = 'foo'
foo = print_foo(foo)
