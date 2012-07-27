require_relative 'spec_helper'
require 'redstone_bot/inventory'

describe RedstoneBot::Inventory do
  before do
    @client = TestClient.new
    @inventory = described_class.new(@client)
  end
  
  it "responds to SetWindowItems packets for window 0" do
    slots_data = [nil]*45
    slots_data[36] = {item_id: 296, count: 31, damage: 0}
    slots_data[37] = {item_id: 295, count: 46, damage: 10}
    p = RedstoneBot::Packet::SetWindowItems.create(0, slots_data)
    @client << p
    @inventory.slots[36].item_type.should == RedstoneBot::ItemType::WheatItem
    RedstoneBot::ItemType::WheatItem.should === @inventory.slots[36]
  end
  
end