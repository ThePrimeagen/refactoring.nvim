module SimpleModule
  class SimpleClass
    def simple_function(a)
    puts('SimpleModule#SimpleClass#simple_function') # __AUTO_GENERATED_PRINTF__
      test = 1
      test_other = 11
      for x in test..test_other do
        puts(x, a)
      end
    end
  end
end
