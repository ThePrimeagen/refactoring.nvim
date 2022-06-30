def simple_function
  test = 1
  test_other = 11

  [test, test_other].each do |v|
    puts "#{v}"
  end
end
