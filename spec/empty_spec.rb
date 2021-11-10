require 'redstone_bot/empty'

describe RedstoneBot::Empty do
  it "matches objects that respond to #empty? with true" do
    expect(described_class).to be === []
  end
  
  it "does not match objects that respond to #empty? with false" do
    expect(described_class).not_to be === [1]
  end
  
  it "does not match objects that don't respond to #empty?" do
    expect(described_class).not_to be === 1
  end
end