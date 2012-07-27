require_relative 'spec_helper'
require 'redstone_bot/inventory'

describe RedstoneBot::Inventory do
  before do
    @client = TestClient.new
    @inventory = described_class.new(@client)
  end

  context "before receiving any packets" do
  
    it "has nil slots by default" do
      @inventory.slots.should == [nil]*45
    end
  
    it "reports that it is not loaded" do
      @inventory.should_not be_loaded
    end
  end
  
  it "ignores SetWindowItems packets for non-0 windows" do
    @client << RedstoneBot::Packet::SetWindowItems.create(2, [{item_id: 296, count: 31, damage: 0}]*45)
    @inventory.slots.should == [nil]*45
    @inventory.should_not be_loaded
  end
  
  context "after being loaded" do
    before do
      slots_data = [nil]*45
      slots_data[36] = {item_id: 296, count: 31, damage: 0}
      slots_data[37] = {item_id: 295, count: 46, damage: 10}
      @client << RedstoneBot::Packet::SetWindowItems.create(0, slots_data)
    end

    it "is loaded" do
      @inventory.should be_loaded
    end
    
    it "has stuff in the slots" do
      @inventory.slots[36].item_type.should == RedstoneBot::ItemType::WheatItem
      RedstoneBot::ItemType::WheatItem.should === @inventory.slots[36]
    end
    
    it "can select a slot to hold" do
      @client.should_receive(:send_packet).with(RedstoneBot::Packet::HeldItemChange.new(3))
      @inventory.select_slot 3
    end
  end
  
end