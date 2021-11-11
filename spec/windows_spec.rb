require_relative 'spec_helper'
require 'redstone_bot/models/windows'

shared_examples_for 'uses SpotArray for' do |*array_names|
  array_names.each do |array_name|
    it array_name.to_s do
      expect(subject.send(array_name)).to be_a RedstoneBot::SpotArray
    end
  end
end

describe RedstoneBot::Inventory do
  it "has general purpose spots" do
    expect(subject.general_spots.size).to eq(36)
  end

  it "has 9 hotbar spots" do
    expect(subject.hotbar_spots.size).to eq(9)
  end
  
  it "has hotbar spots at the end of the general spots array" do
    # This is required for the spot ids in the InventoryWindow and ChestWindow to be correct
    expect(subject.hotbar_spots).to eq(subject.general_spots[-9,9])
  end

  it "has four spots for armor" do
    expect(subject.armor_spots).to eq([subject.helmet_spot, subject.chestplate_spot, subject.leggings_spot, subject.boots_spot])
  end
  
  it "has easy access to all the spots" do
    expect(subject.spots).to eq(subject.armor_spots + subject.general_spots)
  end
  
  it "has no duplicate spots" do
    expect(subject.spots.uniq).to eq(subject.spots)
  end
    
  it "initially has empty spots" do
    subject.spots.each do |spot|
      expect(spot).to be_a RedstoneBot::Spot
      expect(spot).to be_empty
    end
  end
  
  it_has_behavior 'uses SpotArray for', :armor_spots, :general_spots, :hotbar_spots, :spots
end

describe RedstoneBot::InventoryCrafting do
  it "has four input spots" do
    expect(subject.input_spots).to eq([subject.upper_left, subject.upper_right, subject.lower_left, subject.lower_right])
  end
  
  it "can fetch input spots by row,column" do
    expect(subject.input_spot(0, 0)).to eq(subject.upper_left)
    expect(subject.input_spot(0, 1)).to eq(subject.upper_right)
    expect(subject.input_spot(1, 0)).to eq(subject.lower_left)
    expect(subject.input_spot(1, 1)).to eq(subject.lower_right)
  end
  
  it "has an output spot" do
    expect(subject.output_spot).to be
  end
  
  it "has easy access to all the spots" do
    expect(subject.spots).to eq([subject.output_spot] + subject.input_spots)
  end
  
  it "has no duplicate spots" do
    expect(subject.spots.uniq).to eq(subject.spots)
  end
  
  it_has_behavior 'uses SpotArray for', :input_spots, :spots
end

describe RedstoneBot::Window do
  it "complains if it doesn't recognize the window type" do
    expect { described_class.create(66, nil) }.to raise_error "Unrecognized type of RedstoneBot::Window: 66"
  end
end

describe RedstoneBot::InventoryWindow do
  let(:inventory) { subject.inventory }
  let(:crafting) { subject.crafting }
  let(:spots) { subject.spots }
  
  it "combines inventory and inventory crafting in the proper order" do
    expect(spots).to eq(crafting.spots + inventory.armor_spots +
      inventory.normal_spots + inventory.hotbar_spots)
  end
  
  it "defines the shift regions" do
    expect(subject.shift_region_top).to eq(inventory.normal_spots)
    expect(subject.shift_region_bottom).to eq(inventory.hotbar_spots)
  end

  it "has the right spot ids" do
    # This matches http://www.wiki.vg/File:Inventory-slots.png
    expect(spots[0]).to eq(crafting.output_spot)
    expect(spots[1]).to eq(crafting.upper_left)
    expect(spots[2]).to eq(crafting.upper_right)
    expect(spots[3]).to eq(crafting.lower_left)
    expect(spots[4]).to eq(crafting.lower_right)
    expect(spots[5]).to eq(inventory.helmet_spot)
    expect(spots[6]).to eq(inventory.chestplate_spot)
    expect(spots[7]).to eq(inventory.leggings_spot)
    expect(spots[8]).to eq(inventory.boots_spot)
    expect(spots[9..35]).to eq(inventory.general_spots - inventory.hotbar_spots)
    expect(spots[36..44]).to eq(inventory.hotbar_spots)
  end
  
  it_has_behavior 'uses SpotArray for', :spots, :shift_region_top, :shift_region_bottom
end

describe RedstoneBot::ChestWindow do
  let(:inventory) { RedstoneBot::Inventory.new }

  context "small chest" do
    subject { described_class.new(4, 27, inventory) }
    
    it "has 27 chest spots" do
      expect(subject.chest_spots.size).to eq(27)
    end
    
    it "has 36 spots from the player's inventory" do
      expect(subject.inventory_spots.size).to eq(36)
      expect(subject.inventory_spots).to eq(inventory.general_spots)
    end
    
    it "has 63 total spots" do
      expect(subject.spots.size).to eq(63)
    end
    
    it "has the right spot ids" do
      # http://www.wiki.vg/Inventory#Chest
      expect(subject.spots[0..26]).to eq(subject.chest_spots)
      expect(subject.spots[27..53]).to eq(inventory.general_spots - inventory.hotbar_spots)
      expect(subject.spots[54..62]).to eq(inventory.hotbar_spots)
    end
    
    it "can tell you the spot id of each spot" do
      expect(subject.spot_id(subject.chest_spots[5])).to eq(5)
      expect(subject.spot_id(inventory.general_spots[3])).to eq(27 + 3)
      expect(subject.spot_id(inventory.general_spots[35])).to eq(62)
    end
    
    it "has the right shift regions" do
      expect(subject.shift_region_top).to eq(subject.chest_spots)
      expect(subject.shift_region_bottom).to eq(subject.inventory_spots)
    end
    
    it_has_behavior 'uses SpotArray for', :chest_spots, :inventory_spots, :spots, :shift_region_top, :shift_region_bottom
  end
  
  context "large chest" do
    subject { described_class.new(4, 54, inventory) }
    
    it "has 54 chest spots" do
      expect(subject.chest_spots.size).to eq(54)
    end
  end
end
