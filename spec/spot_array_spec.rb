require_relative 'spec_helper'
require 'redstone_bot/trackers/spot_array'
require 'redstone_bot/trackers/spot'
require 'redstone_bot/protocol/item_types'

describe RedstoneBot::SpotArray do
  let(:items) { [RedstoneBot::ItemType::WoodenShovel * 1, nil, nil, RedstoneBot::ItemType::Gravel * 5, RedstoneBot::ItemType::Gravel * 10] }
  subject { described_class[*items.collect{|i| RedstoneBot::Spot.new(i)}] }

  it "is a module" do
    described_class.should_not be_a Class
    described_class.should be_a Module    
  end

  it "gets mixed into Arrays" do
    subject.should be_a Array
  end  

  it "can be constructed with bracket operators" do
    array = described_class[nil, nil, nil]
    array.should be_a described_class
  end

  it "does not mutate arrays passed to it with splat" do
    original_array = [nil, nil]
    spot_array = described_class[*original_array]
    original_array.should_not be_a described_class
    spot_array << nil
    original_array.should have(2).items
  end
  
  it "can retrieve spots whose items match a specific type using grep" do
    subject.grep(RedstoneBot::ItemType::Gravel).should == [subject[3], subject[4]]
  end
  
  it "can retrieve empty spots using #grep" do
    subject.grep(RedstoneBot::Empty).should == [subject[1], subject[2]]
  end

  it "can retrieve empty spots using #empty_spots" do
    subject.empty_spots.should == [subject[1], subject[2]]
  end
  
  it "#quantity counts the total quatnity of an item type" do
    subject.quantity(RedstoneBot::ItemType::WoodenShovel).should == 1
    subject.quantity(RedstoneBot::ItemType::DiamondShovel).should == 0
    subject.quantity(RedstoneBot::ItemType::Gravel).should == 15
  end
  
end