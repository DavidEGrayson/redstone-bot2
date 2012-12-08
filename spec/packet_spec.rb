require_relative "spec_helper"
require "redstone_bot/protocol/packets"

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
    p.data.should == data
    p.chunk_id.should == chunk_id
    p.should_not be_deallocation
    
    q = RedstoneBot::Packet::ChunkData.create(chunk_id, true, 6, 0xAAAA, data)
    q.ground_up_continuous.should == true
    q.primary_bit_map.should == 6
    q.add_bit_map.should == 0xAAAA
    q.data.should == data
    q.chunk_id.should == chunk_id
  end
  
  it "sometimes indicates deallocation" do
    p = described_class.create_deallocation [32, 16]
    p.chunk_id.should == [32, 16]
    p.ground_up_continuous.should == true
    p.primary_bit_map.should == 0
    p.add_bit_map.should == 0
    p.data.should == "\x01"*256
    p.should be_deallocation
  end
end

describe RedstoneBot::Packet::MapChunkBulk do
  it "correctly parses binary data" do
    metadata = [[[16,256], 0xAAAA, 0], [[16,256], 0xAAAA, 0]]
    data = "whatevers"
    p = described_class.create metadata, data
    p.metadata.should == metadata
    p.data.should == data
  end
end

describe RedstoneBot::Packet::SpawnDroppedItem do
  it "correctly parses binary data" do
     eid = 44
     item_type = RedstoneBot::ItemType::GrassBlock
     count = 13
     metadata = 3
     item = RedstoneBot::Item.new(item_type, count, metadata)
     coords = RedstoneBot::Coords[100.25, 200, 300.03125]
     yaw = -3
     pitch = -128
     roll = 127
     
     p = described_class.create(eid, item, coords, yaw, pitch, roll)
     p.eid.should == eid
     p.item.item_type.should == item_type
     p.item.count.should == count
     p.item.damage.should == metadata
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

describe RedstoneBot::Packet::DestroyEntity do
  it "correctly parses binary data" do
    eids = [12033, 39109013, -30]
    p = described_class.create(eids)
    p.eids.should == eids
  end
end

describe RedstoneBot::Packet::SetWindowItems do
  it "correctly parses binary data" do
    items = [ nil,
      RedstoneBot::ItemType::WheatItem * 31,
      RedstoneBot::Item.new(RedstoneBot::ItemType::IronOre, 44, 0, { "x" => 0 }),
      RedstoneBot::ItemType::ClayBall * 1
    ]
    p = described_class.create(2, items)
    p.window_id.should == 2
    p.items.should == items
  end
end

describe RedstoneBot::Packet::ClientSettings do
  it "encodes binary data correctly" do
    described_class.new("en_US", :far, :enabled, true, 2, true).encode_data.should == "\x00\x05\x00e\x00n\x00_\x00U\x00S\x00\x08\x02\x01"
    described_class.new("en_US", :tiny, :enabled, true, 2, false).encode_data.should == "\x00\x05\x00e\x00n\x00_\x00U\x00S\x03\x08\x02\x00"
  end
end

describe RedstoneBot::Packet::SetSlot do
  it "parses binary data correctly" do
    p = described_class.create(0, 32, RedstoneBot::ItemType::DiamondAxe * 1)
    p.window_id.should == 0
    p.spot_id.should == 32
    p.item.should == RedstoneBot::ItemType::DiamondAxe * 1
  end
end

describe RedstoneBot::Packet::SpawnNamedEntity do
  it "parses binary data correctly" do
    p = described_class.create(48, "Bob", [1, 4, 9])
    p.eid.should == 48
    p.player_name.should == "Bob"
    p.coords.should be_within(0.0001).of(RedstoneBot::Coords[1, 4, 9])
    # TODO: test other fields of this packet
  end
end

describe RedstoneBot::Packet::OpenWindow do
  it "parses binary data correctly" do
    p = described_class.create(2, 0, "container.chest", 27)
    p.window_id.should == 2
    p.type.should == 0
    p.title.should == "container.chest"
    p.spot_count.should == 27
  end
end

describe RedstoneBot::Packet::CloseWindow do
  it "parses binary data correctly" do
    p = described_class.create(44)
    p.window_id.should == 44
  end
end

describe RedstoneBot::Packet::EntityEquipment do
  it "parses binary data correctly" do
    p = described_class.create(3, 4, RedstoneBot::ItemType::WoodenAxe * 1)
    p.eid.should == 3
    p.spot_id.should == 4
    p.item.should == RedstoneBot::ItemType::WoodenAxe * 1
  end
end

describe RedstoneBot::Packet::EntityTeleport do
  it "parses binary data correctly" do
    p = described_class.create(10, [9, 1, -1], -90, 45)
    p.eid.should == 10
    p.coords.should == RedstoneBot::Coords[9, 1, -1]
    p.yaw.should == -90
    p.pitch.should == 45
  end
end

describe RedstoneBot::Packet::EntityLookAndRelativeMove do
  it "parses binary data correctly" do
    p = described_class.create(20, [1.5, 1.25, 0.125], -89, 46)
    p.eid.should == 20
    p.coords_change.should be_within(0.00001).of(RedstoneBot::Coords[1.5, 1.25, 0.125])
    p.yaw.should == -89
    p.pitch.should == 46
  end
end

describe RedstoneBot::Packet::EntityRelativeMove do
  it "parses binary data correctly" do
    p = described_class.create(21, [1.5, 1.25, -0.125])
    p.eid.should == 21
    p.coords_change.should be_within(0.00001).of(RedstoneBot::Coords[1.5, 1.25, -0.125])
  end
end