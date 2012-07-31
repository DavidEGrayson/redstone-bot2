require_relative 'spec_helper'
require 'redstone_bot/inventory'

describe RedstoneBot::Inventory do
  before do
    @client = TestClient.new
    @inventory = described_class.new(@client)
  end
  
  it "ignores SetWindowItems packets for non-0 windows" do
    RedstoneBot::Slot.new(RedstoneBot::ItemType::Bread, 44).encode_data
  
    @client << RedstoneBot::Packet::SetWindowItems.create(2, [RedstoneBot::Slot.new(RedstoneBot::ItemType::Bread, 44)]*45)
    @inventory.slots.should == [nil]*45
    @inventory.should_not be_loaded
  end
  
  context "before being loaded" do  
    it "has nil slots" do
      @inventory.slots.should == [nil]*45
    end
  
    it "is not loaded" do
      @inventory.should_not be_loaded
    end
    
    it "is empty" do
      @inventory.should be_empty
    end
    
    it "is pending" do
      @inventory.should be_pending
    end
  end
  
  context "after being loaded" do
    before do
      slots = [nil]*45
      slots[10] = RedstoneBot::Slot.new(RedstoneBot::ItemType::IronShovel, 1, 2, "fake enchant data")
      slots[36] = RedstoneBot::Slot.new(RedstoneBot::ItemType::WheatItem, 31)
      slots[37] = RedstoneBot::Slot.new(RedstoneBot::ItemType::Bread, 44)
      @client << RedstoneBot::Packet::SetWindowItems.create(0, slots)
    end

    it "is loaded" do
      @inventory.should be_loaded
    end
    
    it "is not empty" do
      @inventory.should_not be_empty
    end
    
    it "has stuff in the slots" do
      @inventory.slots[36].item_type.should == RedstoneBot::ItemType::WheatItem
      RedstoneBot::ItemType::WheatItem.should === @inventory.slots[36]
    end
    
    it "can select a slot to hold" do
      @client.should_receive(:send_packet).with(RedstoneBot::Packet::HeldItemChange.new(3))
      @inventory.select_hotbar_slot 3
    end
        
    it "has a nice include? method" do
      @inventory.should include RedstoneBot::ItemType::IronShovel
      @inventory.should include RedstoneBot::ItemType::WheatItem
      @inventory.should include RedstoneBot::ItemType::Bread
      @inventory.should_not include RedstoneBot::ItemType::EmeraldOre      
    end
    
    it "has a nice hotbar_include? method" do
      @inventory.should_not be_hotbar_include(RedstoneBot::ItemType::IronShovel)
      @inventory.should be_hotbar_include(RedstoneBot::ItemType::Bread)
    end
  end
  
end