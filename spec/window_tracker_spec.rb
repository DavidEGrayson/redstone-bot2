require_relative 'spec_helper'
require 'redstone_bot/trackers/window_tracker'

describe RedstoneBot::WindowTracker::Inventory do
  it "has general purpose spots" do
    subject.should have(36).regular_spots
  end  

  it "has 9 hotbar spots" do
    subject.should have(9).hotbar_spots
  end
  
  it "has hotbar spots at the end of the regular spots array" do
    subject.hotbar_spots.should == subject.regular_spots[-9,9]
  end

  it "has four spots for armor" do
    subject.armor_spots.should == [subject.helmet_spot, subject.chestplate_spot, subject.leggings_spot, subject.boots_spot]
  end
  
  it "has easy access to all the spots" do
    subject.spots.should == subject.regular_spots + subject.armor_spots
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
end

describe RedstoneBot::WindowTracker::InternalCrafting do
  it "has four input spots" do
    subject.input_spots.should == [subject.upper_left, subject.upper_right, subject.lower_left, subject.lower_right]
  end
  
  it "can fetch input slots by row,column" do
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
end

#describe RedstoneBot::WindowTracker::InventoryWindow do
#  let(:inventory) { RedstoneBot::WindowTracker::Inventory.new }
#  subject { described_class.new(inventory, crafting) }
#end

describe RedstoneBot::WindowTracker::ChestWindow do
  let(:inventory) { RedstoneBot::WindowTracker::Inventory.new }

  context "small chest" do
    subject { described_class.new(27, inventory) }
    
    it "has 27 chest spots" do
      subject.should have(27).chest_spots
    end
    
    it "has 36 spots from the player's inventory" do
      subject.should have(36).inventory_spots
      subject.inventory_spots.should == inventory.regular_spots
    end
    
    it "has 63 total spots" do
      subject.should have(63).spots
      subject.spots.should == subject.chest_spots + subject.inventory_spots
    end
    
    it "can tell you the spot id of each spot" do
      subject.spot_id(subject.chest_spots[5]).should == 5
      subject.spot_id(inventory.regular_spots[3]).should == 27 + 3
      subject.spot_id(inventory.regular_spots[35]).should == 62
    end
  end
  
  context "large chest" do
    subject { described_class.new(54, inventory) }
    
    it "has 54 chest spots" do
      subject.should have(54).chest_spots
    end
  end
end

describe RedstoneBot::WindowTracker do
  let(:client) { TestClient.new }
  subject { RedstoneBot::WindowTracker.new(client) }
  
  it "ignores random other packets" do
    subject << RedstoneBot::Packet::KeepAlive.new
  end
  
  it "has an inventory" do
    subject.inventory.should be_a RedstoneBot::WindowTracker::Inventory
  end
  
  context "initially" do
    it "has no open window" do
      subject.open_window.should == nil
    end
  end
  
  context "after a chest is opened" do
    before do
      subject << RedstoneBot::Packet::OpenWindow.create(2, 0, "container.chest", 27)
    end
    
    #pending "ignores SetWindowItem packets for other windows" do
    #  subject << RedstoneBot::Packet::SetWindowItems.create(16, [nil, nil])
    #end
  end
  
  context "after a double chest is opened" do
    before do
      subject << RedstoneBot::Packet::OpenWindow.create(2, 0, "container.chestDouble", 54)
    end
    
    #pending { subject.window_title.should == :chest_double }    
  end

end