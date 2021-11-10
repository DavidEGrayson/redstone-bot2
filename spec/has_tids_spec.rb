require_relative 'spec_helper'
require 'redstone_bot/has_tids'

module HasTidsSpec
  class A
    extend RedstoneBot::HasTids  
  end
  
  class A1 < A
    tid_is 1
  end
  
  class B
    extend RedstoneBot::HasTids
  end
  
  class B2 < B
    tid_is 2
  end
  
  describe RedstoneBot::HasTids do
    it "keeps a hash that associates type to subclass" do
      expect(A.types[1]).to eq(A1)
    end
  
    it "lets each class tree have a different types hash" do
      expect(A.types).not_to eq(B.types)
    end
    
    it "has a #tid method on each subclass" do
      expect(B2.tid).to eq(2)
    end
  end
end