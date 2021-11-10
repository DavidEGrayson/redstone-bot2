require_relative 'spec_helper'
require 'redstone_bot/models/spot'
require 'redstone_bot/protocol/item_types'

describe RedstoneBot::Spot do
  context "when initialized without arguments" do
    it "is empty" do
      expect(subject).to be_empty
    end
    
    it "returns nil for item_type" do
      expect(subject.item_type).to eq(nil)
    end
  end

  context "when initialized with some item data" do
    subject { described_class.new(RedstoneBot::ItemType::DiamondBlock * 1) }
    
    it "stores the data" do
      expect(subject.item).to eq(RedstoneBot::ItemType::DiamondBlock * 1)
    end
    
    it "is not empty" do
      expect(subject).not_to be_empty
    end
    
    it "delegates item_type to the item" do
      subject.item = RedstoneBot::ItemType::DiamondBlock * 1
      expect(subject.item_type).to eq(RedstoneBot::ItemType::DiamondBlock)
    end
  end

  it "can be changed" do
    subject.item = RedstoneBot::ItemType::GrassBlock * 1
  end
  
  it "compares by identity, not anything else" do
    expect(described_class.new).not_to eq(described_class.new)
    
    spot = described_class.new
    expect(spot).to eq(spot)
  end
  
end
