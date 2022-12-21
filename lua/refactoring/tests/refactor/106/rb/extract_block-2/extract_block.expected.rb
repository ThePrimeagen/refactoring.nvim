
def foo_bar()
  test = 1
  test_other = 11

  [test, test_other].each do |v|
    puts "#{v}"
  end
end

def simple_function
  foo_bar()
end
