require_relative 'spec_helper'
require 'redstone_bot/models/windows'

shared_examples_for 'uses SpotArray for' do |*array_names|
  array_names.each do |array_name|
    it array_name.to_s do
      subject.send(array_name).should be_a RedstoneBot::SpotArray
    end
  end
end

describe RedstoneBot::Inventory do
  it "has general purpose spots" do
    subject.should have(36).general_spots
  end

  it "has 9 hotbar spots" do
    subject.should have(9).hotbar_spots
  end
  
  it "has hotbar spots at the end of the general spots array" do
    # This is required for the spot ids in the InventoryWindow and ChestWindow to be correct
    subject.hotbar_spots.should == subject.general_spots[-9,9]
  end

  it "has four spots for armor" do
    subject.armor_spots.should == [subject.helmet_spot, subject.chestplate_spot, subject.leggings_spot, subject.boots_spot]
  end
  
  it "has easy access to all the spots" do
    subject.spots.should == subject.armor_spots + subject.general_spots
  end
  
  it "has no duplicate spots" do
    subject.spots.uniq.should == subject.spots
  end
    
  it "initially has empty spots" do
    subject.spots.each do |spot|
      spot.should be_a RedstoneBot::Spot
      spot.should be_empty
    end
  end
  
  it_has_behavior 'uses SpotArray for', :armor_spots, :general_spots, :hotbar_spots, :spots
end

describe RedstoneBot::InventoryCrafting do
  it "has four input spots" do
    subject.input_spots.should == [subject.upper_left, subject.upper_right, subject.lower_left, subject.lower_right]
  end
  
  it "can fetch input spots by row,column" do
    subject.input_spot(0, 0).should == subject.upper_left
    subject.input_spot(0, 1).should == subject.upper_right
    subject.input_spot(1, 0).should == subject.lower_left
    subject.input_spot(1, 1).should == subject.lower_right
  end
  
  it "has an output spot" do
    subject.output_spot.should be
  end
  
  it "has easy access to all the spots" do
    subject.spots.should == [subject.output_spot] + subject.input_spots
  end
  
  it "has no duplicate spots" do
    subject.spots.uniq.should == subject.spots
  end
  
  it_has_behavior 'uses SpotArray for', :input_spots, :spots
end

describe RedstoneBot::Window do
  it "complains if it doesn't recognize the window type" do
    lambda { described_class.create(66, nil) }.should raise_error "Unrecognized type of RedstoneBot::Window: 66"
  end
end

describe RedstoneBot::InventoryWindow do
  let(:inventory) { subject.inventory }
  let(:crafting) { subject.crafting }
  let(:spots) { subject.spots }
  
  it "combines inventory and inventory crafting in the proper order" do
    spots.should == crafting.spots + inventory.armor_spots +
      inventory.normal_spots + inventory.hotbar_spots
  end
  
  it "defines the shift regions" do
    subject.shift_region_top.should == inventory.normal_spots
    subject.shift_region_bottom.should == inventory.hotbar_spots
  end

  it "has the right spot ids" do
    # This matches http://www.wiki.vg/File:Inventory-slots.png
    spots[0].should == crafting.output_spot
    spots[1].should == crafting.upper_left
    spots[2].should == crafting.upper_right
    spots[3].should == crafting.lower_left
    spots[4].should == crafting.lower_right
    spots[5].should == inventory.helmet_spot
    spots[6].should == inventory.chestplate_spot
    spots[7].should == inventory.leggings_spot
    spots[8].should == inventory.boots_spot
    spots[9..35].should == inventory.general_spots - inventory.hotbar_spots
    spots[36..44].should == inventory.hotbar_spots
  end
  
  it_has_behavior 'uses SpotArray for', :spots, :shift_region_top, :shift_region_bottom
end

describe RedstoneBot::ChestWindow do
  let(:inventory) { RedstoneBot::Inventory.new }

  context "small chest" do
    subject { described_class.new(4, 27, inventory) }
    
    it "has 27 chest spots" do
      subject.should have(27).chest_spots
    end
    
    it "has 36 spots from the player's inventory" do
      subject.should have(36).inventory_spots
      subject.inventory_spots.should == inventory.general_spots
    end
    
    it "has 63 total spots" do
      subject.should have(63).spots
    end
    
    it "has the right spot ids" do
      # http://www.wiki.vg/Inventory#Chest
      subject.spots[0..26].should == subject.chest_spots
      subject.spots[27..53].should == inventory.general_spots - inventory.hotbar_spots
      subject.spots[54..62].should == inventory.hotbar_spots
    end
    
    it "can tell you the spot id of each spot" do
      subject.spot_id(subject.chest_spots[5]).should == 5
      subject.spot_id(inventory.general_spots[3]).should == 27 + 3
      subject.spot_id(inventory.general_spots[35]).should == 62
    end
    
    it "has the right shift regions" do
      subject.shift_region_top.should == subject.chest_spots
      subject.shift_region_bottom.should == subject.inventory_spots
    end
    
    it_has_behavior 'uses SpotArray for', :chest_spots, :inventory_spots, :spots, :shift_region_top, :shift_region_bottom
  end
  
  context "large chest" do
    subject { described_class.new(4, 54, inventory) }
    
    it "has 54 chest spots" do
      subject.should have(54).chest_spots
    end
  end
end
