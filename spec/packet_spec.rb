require_relative "spec_helper"
require "redstone_bot/protocol/packets"

describe RedstoneBot::Packet::BlockChange do
  it "correctly parses binary data" do
    bc = described_class.create([70,80,900], 44, 3)
    expect(bc.x).to eq(70)
    expect(bc.y).to eq(80)
    expect(bc.z).to eq(900)
    expect(bc.chunk_id).to eq([70/16*16, 900/16*16])
    expect(bc.block_type_id).to eq(44)
    expect(bc.block_metadata).to eq(3)
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
    expect(mbc.chunk_id).to eq([0, 16])
    expect(mbc.to_enum.to_a).to eq([
      [[10,1,7], RedstoneBot::ItemType::Piston.id, 0],
      [[10,2,7], RedstoneBot::ItemType::Piston.id, 1],
      [[10,3,7], RedstoneBot::ItemType::Piston.id, 2],
      [[10,4,7], RedstoneBot::ItemType::Piston.id, 3],
    ])
  end
end

describe RedstoneBot::Packet::ChunkData do
  it "correctly parses binary data" do
    data = ("\x00".."\xFF").to_a.join
    chunk_id = [96,256]
    p = described_class.create(chunk_id, true, 0xFFFF, 5, data)
    expect(p.ground_up_continuous).to eq(true)
    expect(p.primary_bit_map).to eq(0xFFFF)
    expect(p.add_bit_map).to eq(5)
    expect(p.data).to eq(data)
    expect(p.chunk_id).to eq(chunk_id)
    expect(p).not_to be_deallocation
    
    q = RedstoneBot::Packet::ChunkData.create(chunk_id, true, 6, 0xAAAA, data)
    expect(q.ground_up_continuous).to eq(true)
    expect(q.primary_bit_map).to eq(6)
    expect(q.add_bit_map).to eq(0xAAAA)
    expect(q.data).to eq(data)
    expect(q.chunk_id).to eq(chunk_id)
  end
  
  it "sometimes indicates deallocation" do
    p = described_class.create_deallocation [32, 16]
    expect(p.chunk_id).to eq([32, 16])
    expect(p.ground_up_continuous).to eq(true)
    expect(p.primary_bit_map).to eq(0)
    expect(p.add_bit_map).to eq(0)
    expect(p.data).to eq("\x01"*256)
    expect(p).to be_deallocation
  end
end

describe RedstoneBot::Packet::MapChunkBulk do
  it "correctly parses binary data" do
    metadata = [[[16,256], 0xAAAA, 0], [[16,256], 0xAAAA, 0]]
    data = "whatevers"
    p = described_class.create metadata, data
    expect(p.metadata).to eq(metadata)
    expect(p.data).to eq(data)
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
    expect(p.eid).to eq(eid)
    expect(p.type).to eq(type)
    expect(p.coords).to be_within(0.00001).of(coords)
    expect(p.yaw).to eq(yaw)
    expect(p.pitch).to eq(pitch)
    expect(p.head_yaw).to eq(head_yaw)
  end
end

describe RedstoneBot::Packet::DestroyEntity do
  it "correctly parses binary data" do
    eids = [12033, 39109013, -30]
    p = described_class.create(eids)
    expect(p.eids).to eq(eids)
  end
end

describe RedstoneBot::Packet::SetWindowItems do
  it "correctly parses binary data" do
    items = [ nil,
      RedstoneBot::ItemType::WheatItem * 31,
      RedstoneBot::Item.new(RedstoneBot::ItemType::IronOre, 44, 0, { :flame => 0 }),
      RedstoneBot::ItemType::ClayBall * 1
    ]
    p = described_class.create(2, items)
    expect(p.window_id).to eq(2)
    expect(p.items).to eq(items)
  end
end

describe RedstoneBot::Packet::ClientSettings do
  it "encodes binary data correctly" do
    expect(described_class.new("en_US", :far, :enabled, true, 2, true).encode_data).to eq("\x00\x05\x00e\x00n\x00_\x00U\x00S\x00\x08\x02\x01")
    expect(described_class.new("en_US", :tiny, :enabled, true, 2, false).encode_data).to eq("\x00\x05\x00e\x00n\x00_\x00U\x00S\x03\x08\x02\x00")
  end
end

describe RedstoneBot::Packet::SetSlot do
  it "parses binary data correctly" do
    p = described_class.create(0, 32, RedstoneBot::ItemType::DiamondAxe * 1)
    expect(p.window_id).to eq(0)
    expect(p.spot_id).to eq(32)
    expect(p.item).to eq(RedstoneBot::ItemType::DiamondAxe * 1)
  end
end

describe RedstoneBot::Packet::SpawnNamedEntity do
  it "parses binary data correctly" do
    p = described_class.create(48, "Bob", [1, 4, 9])
    expect(p.eid).to eq(48)
    expect(p.player_name).to eq("Bob")
    expect(p.coords).to be_within(0.0001).of(RedstoneBot::Coords[1, 4, 9])
    # TODO: test other fields of this packet
  end
end

describe RedstoneBot::Packet::OpenWindow do
  it "parses binary data correctly" do
    p = described_class.create(2, 0, "container.chest", 27)
    expect(p.window_id).to eq(2)
    expect(p.type).to eq(0)
    expect(p.title).to eq("container.chest")
    expect(p.spot_count).to eq(27)
  end
end

describe RedstoneBot::Packet::CloseWindow do
  it "parses binary data correctly" do
    p = described_class.create(44)
    expect(p.window_id).to eq(44)
  end
end

describe RedstoneBot::Packet::EntityEquipment do
  it "parses binary data correctly" do
    p = described_class.create(3, 4, RedstoneBot::ItemType::WoodenAxe * 1)
    expect(p.eid).to eq(3)
    expect(p.spot_id).to eq(4)
    expect(p.item).to eq(RedstoneBot::ItemType::WoodenAxe * 1)
  end
end

describe RedstoneBot::Packet::EntityTeleport do
  it "parses binary data correctly" do
    p = described_class.create(10, [9, 1, -1], -90, 45)
    expect(p.eid).to eq(10)
    expect(p.coords).to eq(RedstoneBot::Coords[9, 1, -1])
    expect(p.yaw).to eq(-90)
    expect(p.pitch).to eq(45)
  end
end

describe RedstoneBot::Packet::EntityLookAndRelativeMove do
  it "parses binary data correctly" do
    p = described_class.create(20, [1.5, 1.25, 0.125], -89, 46)
    expect(p.eid).to eq(20)
    expect(p.coords_change).to be_within(0.00001).of(RedstoneBot::Coords[1.5, 1.25, 0.125])
    expect(p.yaw).to eq(-89)
    expect(p.pitch).to eq(46)
  end
end

describe RedstoneBot::Packet::EntityRelativeMove do
  it "parses binary data correctly" do
    p = described_class.create(21, [1.5, 1.25, -0.125])
    expect(p.eid).to eq(21)
    expect(p.coords_change).to be_within(0.00001).of(RedstoneBot::Coords[1.5, 1.25, -0.125])
  end
end

describe RedstoneBot::Packet::KeepAlive do
  it "encodes binary data correctly" do
    p = described_class.new(5)
    expect(p.encode).to eq("\x00\x00\x00\x00\x05")
  end
end