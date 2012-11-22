require_relative 'spec_helper'
require 'redstone_bot/trackers/window_tracker'

describe RedstoneBot::WindowTracker::Spot do
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
  
  it "initially has empty spots" do
    subject.spots.each do |spot|
      spot.should be_a RedstoneBot::WindowTracker::Spot
      spot.should be_empty
    end
  end
  
end

describe RedstoneBot::WindowTracker do
  let(:client) { TestClient.new }
  subject { RedstoneBot::WindowTracker.new(client) }
  
  it "ignores random other packets" do
    subject << RedstoneBot::Packet::KeepAlive.new
  end
  
  context "initially" do
  end
  
  context "after a chest is opened" do
    before do
      subject << RedstoneBot::Packet::OpenWindow.create(2, 0, "container.chest", 27)
    end
    
    pending "ignores SetWindowItem packets for other windows" do
      subject << RedstoneBot::Packet::SetWindowItems.create(16, [nil, nil])
    end
  end
  
  context "after a double chest is opened" do
    before do
      subject << RedstoneBot::Packet::OpenWindow.create(2, 0, "container.chestDouble", 54)
    end
    
    pending { subject.window_title.should == :chest_double }    
  end

end