require_relative 'spec_helper'
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
  
  it "tracks mobs" do
    eid = 45
    type = 50   # Creeper
    coords = RedstoneBot::Coords[100.25, 200, 300.03125]
    yaw = -1
    pitch = -2
    head_yaw = -3
    p = RedstoneBot::Packet::SpawnMob.create(eid, type, coords, yaw, pitch, head_yaw)
    @client << p
    
    creepers = @entity_tracker.entities_of_type(RedstoneBot::Creeper)
    creepers.size.should == 1
    creeper = creepers.first
    creeper.eid.should == 45
    creeper.should be_a_kind_of RedstoneBot::Mob
    creeper.position.should be_within(0.00001).of(coords)
    creeper.to_s.should == "Creeper(45, ( 100.25, 200.00, 300.03))"
  end
  
end