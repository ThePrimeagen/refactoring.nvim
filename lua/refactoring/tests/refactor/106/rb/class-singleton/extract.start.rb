class SimpleClass
  def self.simple_function(a)
    test = 1
    test_other = 11

    [test, test_other].each do |v|
      puts "#{a} #{v}"
    end
  end
end
