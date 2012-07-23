require_relative 'spec_helper'
require 'zlib'
require 'redstone_bot/coords'

module RedstoneBot
  def (Packet::BlockChange).create(coords, block_type_id, block_metadata)
    receive_data test_stream (coords + [block_type_id, block_metadata]).pack('l>Cl>CC')
  end
  
  def (Packet::ChunkAllocation).create(chunk_id, mode)
    receive_data test_stream [chunk_id[0]/16, chunk_id[1]/16, mode ? 1 : 0].pack('l>l>C')
  end
  
  def (Packet::MultiBlockChange).create(block_changes)
    block_changes = block_changes.collect do |c|
      c = RedstoneBot::Packet::BlockChange.create(*c) unless c.respond_to?(:x)
    end

    chunk_id = block_changes[0].chunk_id
  
    binary_data = [chunk_id[0]/16, chunk_id[1]/16, block_changes.size, 4*block_changes.size].pack("l>l>S>l>")
    binary_data += block_changes.collect do |c|
      [(c.x%16)+((c.z%16)<<4), c.y, (c.block_type_id<<4) + (c.block_metadata&0xF)].pack("CCs>")
    end.join
    
    receive_data test_stream binary_data
  end
  
  def (Packet::ChunkData).create(chunk_id, ground_up_continuous, primary_bit_map, add_bit_map, data)
    compressed = Zlib::Deflate.deflate(data)
    binary_data = [chunk_id[0]/16, chunk_id[1]/16,
      ground_up_continuous ? 1 : 0,
      primary_bit_map, add_bit_map,
      compressed.size, 0
    ].pack("l>l>CS>S>l>l>") + compressed
    receive_data test_stream binary_data
  end
  
  def (Packet::SpawnDroppedItem).create(eid, item, count, metadata, coords, yaw, pitch, roll)
    binary_data = [eid, item, count, metadata,
     (coords[0]*32).round, (coords[1]*32).round, (coords[2]*32).round,
     yaw, pitch, roll
    ].pack("l>s>Cs>l>l>l>ccc")
    receive_data test_stream binary_data
  end
end

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
      [[10,1,23], RedstoneBot::BlockType::Piston.id, 0],
      [[10,2,23], RedstoneBot::BlockType::Piston.id, 1],
      [[10,3,23], RedstoneBot::BlockType::Piston.id, 2],
      [[10,4,23], RedstoneBot::BlockType::Piston.id, 3]
    ])    
    mbc.chunk_id.should == [0, 16]
    mbc.to_enum.to_a.should == [
      [[10,1,7], RedstoneBot::BlockType::Piston.id, 0],
      [[10,2,7], RedstoneBot::BlockType::Piston.id, 1],
      [[10,3,7], RedstoneBot::BlockType::Piston.id, 2],
      [[10,4,7], RedstoneBot::BlockType::Piston.id, 3],
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