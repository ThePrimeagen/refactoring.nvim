
def foo_bar(test)
  test_other = 11

    [test, test_other].each do |v|
      puts "#{v}"
    end
end

def simple_function
  test = 1
  foo_bar(test)
end
