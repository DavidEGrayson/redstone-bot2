require_relative 'spec_helper'
require 'redstone_bot/trackers/spot'

describe RedstoneBot::Spot do
  context "when initialized without arguments" do
    it "is empty" do
      subject.should be_empty
    end
  end

  context "when initialized with some item data" do
    subject { described_class.new(RedstoneBot::ItemType::DiamondBlock * 1) }
    
    it "stores the data" do
      subject.item.should == RedstoneBot::ItemType::DiamondBlock * 1
    end
    
    it "is not empty" do
      subject.should_not be_empty
    end
  end

  it "can be changed" do
    subject.item = RedstoneBot::ItemType::GrassBlock * 1
  end
  
  it "compares by identity, not anything else" do
    described_class.new.should_not == described_class.new
    
    spot = described_class.new
    spot.should == spot
  end
  
end