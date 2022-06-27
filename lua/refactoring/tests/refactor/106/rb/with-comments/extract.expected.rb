# This is a comment
# Ruby still rocks

def foo_bar(a, test, test_other)
  [test, test_other].each do |v|
    puts "#{a} #{v}"
  end
end

# It's not dead
def simple_function(a)
  test = 1
  test_other = 11

  foo_bar(a, test, test_other)
end
