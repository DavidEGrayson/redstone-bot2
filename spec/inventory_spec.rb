require_relative 'spec_helper'
require 'redstone_bot/inventory'

describe RedstoneBot::Inventory do
  before do
    @client = TestClient.new
    @inventory = described_class.new(@client)
  end
  
  it "ignores SetWindowItems packets for non-0 windows" do
    @client << RedstoneBot::Packet::SetWindowItems.create(2, [{item_id: 296, count: 31, damage: 0}]*45)
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
  end
  
  context "after being loaded" do
    before do
      slots_data = [nil]*45
      slots_data[36] = {item_id: RedstoneBot::ItemType::WheatItem.id, count: 31, damage: 0}
      slots_data[37] = {item_id: RedstoneBot::ItemType::Bread.id, count: 46, damage: 10}
      @client << RedstoneBot::Packet::SetWindowItems.create(0, slots_data)
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
      @inventory.select_slot 3
    end
        
    it "has a nice include? method" do
      @inventory.should include RedstoneBot::ItemType::WheatItem
      @inventory.should include RedstoneBot::ItemType::Bread
      @inventory.should_not include RedstoneBot::ItemType::EmeraldOre      
    end
    
  end
  
end