require_relative 'spec_helper'
require 'zlib'
require 'redstone_bot/coords'

describe RedstoneBot::Packet::BlockChange do
  it "correctly parses binary data" do
    bc = described_class.create([70,80,900], 44, 3)
    bc.x.should == 70
    bc.y.should == 80
    bc.z.should == 900
    bc.chunk_id.should == [70/16*16, 900/16*16]
    bc.block_type_id.should == 44
    bc.block_metadata.should == 3
  end
end

describe RedstoneBot::Packet::ChunkAllocation do
  it "correctly parses binary data" do
    ca = described_class.create([7*16, 8*16], true)
    ca.mode.should == true
    ca.chunk_id.should == [7*16, 8*16]

    ca = described_class.create([7*16, 8*16], false)
    ca.mode.should == false
  end
end

describe RedstoneBot::Packet::MultiBlockChange do
  it "correctly parses binary data" do
    mbc = described_class.create([
      [[10,1,23], RedstoneBot::ItemType::Piston.id, 0],
      [[10,2,23], RedstoneBot::ItemType::Piston.id, 1],
      [[10,3,23], RedstoneBot::ItemType::Piston.id, 2],
      [[10,4,23], RedstoneBot::ItemType::Piston.id, 3]
    ])    
    mbc.chunk_id.should == [0, 16]
    mbc.to_enum.to_a.should == [
      [[10,1,7], RedstoneBot::ItemType::Piston.id, 0],
      [[10,2,7], RedstoneBot::ItemType::Piston.id, 1],
      [[10,3,7], RedstoneBot::ItemType::Piston.id, 2],
      [[10,4,7], RedstoneBot::ItemType::Piston.id, 3],
    ]
  end
end

describe RedstoneBot::Packet::ChunkData do
  it "correctly parses binary data" do
    data = ("\x00".."\xFF").to_a.join
    chunk_id = [96,256]
    p = described_class.create(chunk_id, true, 0xFFFF, 5, data)
    p.ground_up_continuous.should == true
    p.primary_bit_map.should == 0xFFFF
    p.add_bit_map.should == 5
    Zlib::Inflate.inflate(p.compressed_data).should == data
    p.chunk_id.should == chunk_id

    q = RedstoneBot::Packet::ChunkData.create(chunk_id, true, 6, 0xAAAA, data)
    q.ground_up_continuous.should == true
    q.primary_bit_map.should == 6
    q.add_bit_map.should == 0xAAAA
    Zlib::Inflate.inflate(q.compressed_data).should == data
    q.chunk_id.should == chunk_id
  end
end

describe RedstoneBot::Packet::SpawnDroppedItem do
  it "correctly parses binary data" do
     eid = 44
     item = 2
     count = 13
     metadata = 3
     coords = RedstoneBot::Coords[100.25, 200, 300.03125]
     yaw = -3
     pitch = -128
     roll = 127
     
     p = described_class.create(eid, item, count, metadata, coords, yaw, pitch, roll)
     p.eid.should == eid
     p.item.should == item
     p.count.should == count
     p.metadata.should == 3
     p.coords.should be_within(0.00001).of(coords)
     p.yaw.should == yaw
     p.pitch.should == pitch
     p.roll.should == roll
  end
end

describe RedstoneBot::Packet::SpawnMob do
  it "correctly parses binary data" do
    eid = 45
    type = 50   # Creeper
    coords = RedstoneBot::Coords[100.25, 200, 300.03125]
    yaw = -1
    pitch = -2
    head_yaw = -3
    p = described_class.create(eid, type, coords, yaw, pitch, head_yaw)
    p.eid.should == eid
    p.type.should == type
    p.coords.should be_within(0.00001).of(coords)
    p.yaw.should == yaw
    p.pitch.should == pitch
    p.head_yaw.should == head_yaw
  end
end