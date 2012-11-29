require_relative 'spec_helper'
require 'redstone_bot/tracks_types'

module TracksTypesSpec
  class A
    extend RedstoneBot::TracksTypes    
  end
  
  class A1 < A
    type_is 1
  end
  
  class B
    extend RedstoneBot::TracksTypes    
  end
  
  class B2 < B
    type_is 2
  end
  
  describe RedstoneBot::TracksTypes do
    it "keeps a hash that associates type to subclass" do
      A.types[1].should == A1
    end
  
    it "lets each class tree have a different types hash" do
      A.types.should_not == B.types
    end
    
    it "has a #type method on each subclass" do
      B2.type.should == 2
    end
  end
end