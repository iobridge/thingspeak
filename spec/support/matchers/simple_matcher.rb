RSpec::Matchers.define :be_even do
 match do |given|
   given % 2 == 0
 end
 
 
end

RSpec::Matchers.define :have_ids_of do |objects|
 match do |given|
   (given.map &:id).sort.should == (objects.map &:id).sort
 end
end

# def should_have_ids_of(objcts)
#   simple_matcher("should have id of"){|given | (given.map &:id).sort.should == (objects.map &:id).sort}
# end
# 
# def be_even
#   simple_matcher("an even number") { |given| given % 2 == 0 }
# end
