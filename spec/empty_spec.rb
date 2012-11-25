require 'redstone_bot/empty'

describe RedstoneBot::Empty do
  it "matches objects that respond to #empty? with true" do
    described_class.should === []
  end
  
  it "does not match objects that respond to #empty? with false" do
    described_class.should_not === [1]
  end
  
  it "does not match objects that don't respond to #empty?" do
    described_class.should_not === 1
  end
end