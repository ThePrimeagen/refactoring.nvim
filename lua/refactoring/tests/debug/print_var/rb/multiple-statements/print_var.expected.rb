class SimpleClass
  def simple_function(a)
    test = 1
    test_other = 11
    puts "custom print_var SimpleClass#simple_function test_other: #{test_other}" # __AUTO_GENERATED_PRINT_VAR__
    for x in test..test_other do
      puts x, a
    end
  end
end
