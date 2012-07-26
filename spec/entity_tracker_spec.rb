require_relative 'spec_helper'
require_relative 'packet_spec'
require 'redstone_bot/entity_tracker'

describe RedstoneBot::EntityTracker do
  before do
    @client = TestClient.new
    @entity_tracker = described_class.new(@client, nil)
  end
  
  it "tracks dropped items" do
    eid = 44
    item = 256
    count = 13
    damage = 3
    coords = [100, 200, 300]
    yaw = -3
    pitch = -128
    roll = 127
  
    @client << RedstoneBot::Packet::SpawnDroppedItem.create(eid, item, count, damage, coords, yaw, pitch, roll)
    
    shovels = @entity_tracker.entities_of_type(RedstoneBot::ItemType::IronShovel)
    shovels.size.should == 1
    shovel = shovels.first
    shovel.eid.should == 44
    shovel.should be_a_kind_of RedstoneBot::Item
    RedstoneBot::ItemType::IronShovel.should === shovel
    shovel.to_s.should == "IronShovelx13(44, ( 100.00, 200.00, 300.00), 3)"
  end
  
end