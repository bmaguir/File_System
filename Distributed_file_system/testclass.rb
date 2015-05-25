require "rubygems"
require "json"
class Testclass
  def initialize
    #string = '{"desc":{"someKey":"someValue","anotherKey":"value"},"main_item":{"stats":{"a":8,"b":12,"c":10}}}'
    array = [2,3,4,5,6,3]
    string = '{"type":"NewServer", "array":' + array.to_s + '}'
    parsed = JSON.parse(string) # returns a hash
    puts parsed["array"][1]

    end
end

testclas = Testclass.new