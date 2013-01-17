require_relative 'spec_helper'
require 'redstone_bot/trackers/entity_tracker'

describe RedstoneBot::EntityTracker do
  before do
    @client = TestClient.new
    @entity_tracker = described_class.new(@client, nil)
  end
  
  it "tracks dropped items" do
    eid = 44
    item_type = RedstoneBot::ItemType::IronShovel
    count = 13
    damage = 3
    item = RedstoneBot::Item.new(item_type, count, damage)
    coords = [100, 200, 300]
    yaw = -3
    pitch = -128
    roll = 127
  
    @client << RedstoneBot::Packet::SpawnObject.create(eid, 2, coords, yaw, pitch)
    @client << RedstoneBot::Packet::EntityMetadata.create(eid, item)
    
    shovels = @entity_tracker.entities_of_type(RedstoneBot::ItemType::IronShovel)
    shovels.size.should == 1
    shovel = shovels.first
    shovel.eid.should == 44
    shovel.should be_a_kind_of RedstoneBot::DroppedItem
    RedstoneBot::ItemType::IronShovel.should === shovel
    shovel.to_s.should == "DroppedItem(44, IronShovel*13(damage=3), ( 100.00, 200.00, 300.00))"
  end
  
  it "tracks mobs" do
    # Add two mobs.
    eid = -45
    type = 50   # Creeper
    coords = RedstoneBot::Coords[100.25, 200, 300.03125]
    yaw = -1
    pitch = -2
    head_yaw = -3
    @client << RedstoneBot::Packet::SpawnMob.create(eid, type, coords, yaw, pitch, head_yaw)
    @client << RedstoneBot::Packet::SpawnMob.create(eid+1, type+1, coords, yaw, pitch, head_yaw)

    # Verify two mobs
    @entity_tracker.entities_of_type(RedstoneBot::Mob).size.should == 2
    
    # Examine the creeper
    creepers = @entity_tracker.entities_of_type(RedstoneBot::Creeper)
    creepers.size.should == 1
    creeper = creepers.first
    creeper.eid.should == -45
    creeper.should be_a_kind_of RedstoneBot::Mob
    creeper.coords.should be_a RedstoneBot::Coords
    creeper.coords.should be_within(0.00001).of(coords)
    creeper.to_s.should == "Creeper(-45, ( 100.25, 200.00, 300.03), 0 items)"
    
    # Destroy two mobs
    @client << RedstoneBot::Packet::DestroyEntity.create([-45, -44])
    @entity_tracker.entities_of_type(RedstoneBot::Mob).size.should == 0
  end
  
  context "with a creeper loaded" do
    let(:eid) { 44 }
    let(:creeper) { @entity_tracker.entities_of_type(RedstoneBot::Creeper).first }
    before do
      @client << RedstoneBot::Packet::SpawnMob.create(eid, RedstoneBot::Creeper.tid, [100.25, 200, 300.03125], 0, 0, 0)    
    end

    it "tracks entity equipment" do
      @client << RedstoneBot::Packet::EntityEquipment.create(eid, 4, RedstoneBot::ItemType::LeatherBoots * 1)
      creeper.items.should == [nil, nil, nil, nil, RedstoneBot::ItemType::LeatherBoots * 1]
      creeper.boots.should == RedstoneBot::ItemType::LeatherBoots * 1
    end

    it "tracks teleports" do
      @client << RedstoneBot::Packet::EntityTeleport.create(eid, [10, 40, 1.5], 45, 90)
      creeper.coords.should be_within(0.00001).of(RedstoneBot::Coords[10, 40, 1.5])
    end

    it "tracks relative movements + look packet" do
      @client << RedstoneBot::Packet::EntityLookAndRelativeMove.create(eid, [-0.25, 0.25, -0.03125], 45, 90)
      creeper.coords.should be_within(0.00001).of(RedstoneBot::Coords[100, 200.25, 300])
    end
    
    it "tracks relative movements" do
      @client << RedstoneBot::Packet::EntityRelativeMove.create(eid, [-0.25, 0.25, -0.03125])
      creeper.coords.should be_within(0.00001).of(RedstoneBot::Coords[100, 200.25, 300])
    end

  end
  
  it "does not crash when it gets a packet for an unknown entity" do
    @client << RedstoneBot::Packet::EntityEquipment.create(999, 4, RedstoneBot::ItemType::IronBoots * 1)  
  end
  
  context "with some stuff loaded" do
    before do
      @client << RedstoneBot::Packet::SpawnObject.create(44, 2, [100, 200, 300])
      @client << RedstoneBot::Packet::EntityMetadata.create(44, RedstoneBot::Item.new(RedstoneBot::ItemType::Wool, 1, 2))

      @client << RedstoneBot::Packet::SpawnObject.create(45, 2, [100, 201, 301])
      @client << RedstoneBot::Packet::EntityMetadata.create(45, RedstoneBot::ItemType::Seeds*1)
    
      @client << RedstoneBot::Packet::SpawnNamedEntity.create(46, "Bob", [100, 205, 305])
    end
    
    it "can select entitites by type" do
      @entity_tracker.entities_of_type(RedstoneBot::ItemType::Seeds).collect(&:eid).should == [45]
    end
    
    it "can select entities" do
      @entity_tracker.select { |e| (RedstoneBot::ItemType::WheatItem === e or RedstoneBot::ItemType::Seeds === e) }.collect(&:eid).should == [45]
    end
  end
  
end