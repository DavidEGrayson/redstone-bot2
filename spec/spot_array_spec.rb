require_relative 'spec_helper'
require 'redstone_bot/models/spot_array'
require 'redstone_bot/models/spot'
require 'redstone_bot/protocol/item_types'

describe RedstoneBot::SpotArray do
  let(:items) { [RedstoneBot::ItemType::WoodenShovel * 1, nil, nil, RedstoneBot::ItemType::Gravel * 5, RedstoneBot::ItemType::Gravel * 10] }
  subject { described_class[*items.collect{|i| RedstoneBot::Spot.new(i)}] }

  it "is a module" do
    expect(described_class).not_to be_a Class
    expect(described_class).to be_a Module    
  end

  it "gets mixed into Arrays" do
    expect(subject).to be_a Array
  end  

  it "can be constructed with bracket operators" do
    array = described_class[nil, nil, nil]
    expect(array).to be_a described_class
  end

  it "does not mutate arrays passed to it with splat" do
    original_array = [nil, nil]
    spot_array = described_class[*original_array]
    expect(original_array).not_to be_a described_class
    spot_array << nil
    expect(original_array.size).to eq(2)
  end
  
  it "can retrieve spots whose items match a specific type using grep" do
    expect(subject.grep(RedstoneBot::ItemType::Gravel)).to eq([subject[3], subject[4]])
  end
  
  it "can retrieve empty spots using #grep" do
    expect(subject.grep(RedstoneBot::Empty)).to eq([subject[1], subject[2]])
  end

  it "can retrieve empty spots using #empty_spots" do
    expect(subject.empty_spots).to eq([subject[1], subject[2]])
  end
  
  it "#quantity counts the total quantity of an item type" do
    expect(subject.quantity(RedstoneBot::ItemType::WoodenShovel)).to eq(1)
    expect(subject.quantity(RedstoneBot::ItemType::DiamondShovel)).to eq(0)
    expect(subject.quantity(RedstoneBot::ItemType::Gravel)).to eq(15)
  end
  
  it "#quantity counts the total quantity of all items" do
    expect(subject.quantity).to eq(16)
  end
  
  it "can get and set items" do
    items = [RedstoneBot::ItemType::Jukebox * 1, nil, RedstoneBot::ItemType::LapisOre * 5, nil, nil]        
    subject.items = items
    expect(subject.items).to eq(items)
  end
  
  it "complains if you set the wrong number of items" do
    expect { subject.items = [nil] }.to raise_error    
  end
end