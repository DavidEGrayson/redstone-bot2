require_relative 'spec_helper'
require 'redstone_bot/protocol/item_types'

describe RedstoneBot::ItemType do
  it "can flexibly figure out what block type you want" do
    glass = RedstoneBot::ItemType::Glass
    described_class.from("glass").should == glass
    described_class.from("20").should == glass
    described_class.from("0x14").should == glass
    described_class.from(20).should == glass
    described_class.from(nil).should == nil
    described_class.from("nil").should == nil
    described_class.from("diamond").should == RedstoneBot::ItemType::Diamond
    described_class.from("diamond ore").should == RedstoneBot::ItemType::DiamondOre
  end
  
  it "has items also" do
    described_class.from(256).should == RedstoneBot::ItemType::IronShovel
  end
  
  it "avoids ambiguous names" do
    names = described_class.instance_variable_get(:@types_by_string).keys
    names.size.should > 100
    names.each do |name|
      next if ["diamond", "emerald"].include?(name)
      names.should_not include name + "block"
      names.should_not include name + "item"
    end
  end
  
  it "has a nice matcher" do
    s = double("something")
    s.stub(:item_type) { RedstoneBot::ItemType::IronShovel}
    RedstoneBot::ItemType::IronShovel.should === s
    RedstoneBot::ItemType::IronShovel.should === RedstoneBot::ItemType::IronShovel
    RedstoneBot::ItemType::IronShovel.should === RedstoneBot::Item.new(RedstoneBot::ItemType::IronShovel, 44, 1, nil)
    RedstoneBot::ItemType::WheatItem.should === RedstoneBot::Item.new(RedstoneBot::ItemType::WheatItem)
  end
  
  it "tells you if it is a block or not" do
    RedstoneBot::ItemType::DiamondOre.should be_block
    RedstoneBot::ItemType::Diamond.should_not be_block
  end
  
  it "tells you if it is solid or not" do
    RedstoneBot::ItemType::CoalOre.should be_solid
    RedstoneBot::ItemType::WheatBlock.should_not be_solid
  end
  
  it "tells you how stackable items are" do
    RedstoneBot::ItemType::CoalOre.max_stack.should == 64
    RedstoneBot::ItemType::SignPost.max_stack.should == 16
    RedstoneBot::ItemType::IronShovel.max_stack.should == 1
  
    RedstoneBot::ItemType::SignPost.should be_stackable
    RedstoneBot::ItemType::IronShovel.should_not be_stackable
  end
end