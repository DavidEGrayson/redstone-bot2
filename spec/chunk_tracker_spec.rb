# coding: ASCII-8BIT

require_relative 'spec_helper'
require 'redstone_bot/trackers/chunk_tracker'
require 'zlib'

class RedstoneBot::ChunkTracker
  # Raise an exception instead of just printing to stderr: make it easier to debug
  def handle_update_for_unloaded_chunk(chunk_id)
    raise "Received update for unloaded chunk at #{chunk_id.inspect}"
  end
end
  
bt = ""
# Block Types: 4096 per section
bt << "\x3C" * 256   # y = 0 is all farmland
bt << "\x3B" * 256   # y = 1 is all wheat
bt = bt.ljust(16*256, "\x00")   # the rest of the block types are air
# Metadata: 2048 per section
metadata = ""
metadata << "\x00" * 128   # y = 0 no metadata
metadata << "\x55" * 128   # y = 1 : All crops are 5 tall (7 is the max)
metadata = metadata.ljust(16*128, "\x00")   # the rest of the metadata is 0
# Light: 2048 per section
light = "\x01"*2048
# Sky light: 2048 per section
sky_light = "\x02"*2048
# Biome: plains
biome_data = "\x01"*256
data1 = bt + metadata + light + sky_light + biome_data
testdata1 = RedstoneBot::Packet::ChunkData.create([32,16], false, 1, 0, data1)
bulkdata1 = (bt*16 + metadata*16 + light*16 + sky_light*16 + biome_data)*2
map_chunk_bulk1 = RedstoneBot::Packet::MapChunkBulk.create([[[48,16], 0xFFFF, 0], [[64, 16], 0xFFFF, 0]], bulkdata1)

describe RedstoneBot::Chunk do

  before do
    @chunk = RedstoneBot::Chunk.new([32,16])    
    @chunk.apply_packet testdata1
  end
  
  it "should report farmland at y = 0" do
    expect(@chunk.block_type_id([35,0,17])).to eq(RedstoneBot::ItemType::Farmland.id)
  end
  
  it "should report wheat at y = 1" do
    expect(@chunk.block_type_id([42,1,20])).to eq(RedstoneBot::ItemType::WheatBlock.id)
    
    expect(@chunk.block_type_raw_yslice(1)).to eq("\x3B" * 256)
  end
  
  it "should report metadata=5 at y=1" do
    expect(@chunk.block_metadata([42,1,20])).to eq(5)
  end
  
  it "reports light" do
    expect(@chunk.instance_variable_get(:@light).size).to eq(16)
    expect(@chunk.light([42, 1, 20])).to eq(1)
  end

  it "reports sky light" do
    expect(@chunk.sky_light([42, 1, 20])).to eq(2)
  end
  
  it "can change individual block type and metadata (nibble=0)" do
    wool = double("wool")
    expect(wool).to receive(:to_i).and_return(RedstoneBot::ItemType::Wool.id)
    @chunk.set_block_type_and_metadata([42,1,20], wool, 6)
    expect(@chunk.block_metadata([42,1,20])).to eq(6)
    expect(@chunk.block_type_id([42,1,20])).to eq(RedstoneBot::ItemType::Wool.id)
    expect(@chunk.block_metadata([43,1,20])).to eq(5)
    expect(@chunk.block_type_id([43,1,20])).to eq(RedstoneBot::ItemType::WheatBlock.id)
  end
  
  it "can change individual block type and metadata (nibble=1)" do
    @chunk.set_block_type_and_metadata([45,1,20], RedstoneBot::ItemType::Wool, 6)
    expect(@chunk.block_metadata([44,1,20])).to eq(5)
    expect(@chunk.block_metadata([45,1,20])).to eq(6)
    expect(@chunk.block_type_id([45,1,20])).to eq(RedstoneBot::ItemType::Wool.id)
  end
  
  it "can count blocks by type" do
    expect(@chunk.count_block_type(RedstoneBot::ItemType::Wool)).to eq(0)
    expect(@chunk.count_block_type(RedstoneBot::ItemType::Farmland)).to eq(256)
    expect(@chunk.count_block_type(RedstoneBot::ItemType::WheatBlock)).to eq(256)
    expect(@chunk.count_block_type(RedstoneBot::ItemType::Air)).to eq(14*256)
    expect(@chunk.count_block_type(nil)).to eq(15*16*256)    
  end
end

describe RedstoneBot::ChunkTracker do
  before do
    @client = TestClient.new
    @chunk_tracker = RedstoneBot::ChunkTracker.new(@client)
    @client << testdata1
  end
  
  it "should report farmland at y = 0" do
    expect(@chunk_tracker.block_type([36,0,18])).to eq(RedstoneBot::ItemType::Farmland)
  end

  it "should report wheat at y = 1" do
    expect(@chunk_tracker.block_type(RedstoneBot::Coords[42,1,20])).to eq(RedstoneBot::ItemType::WheatBlock)
  end
  
  it "should report metadata at y = 1" do
    expect(@chunk_tracker.block_metadata([42,1,20])).to eq(5)
  end
  
  it "handles block changes" do
    coords = [42,1,21]
    @client << RedstoneBot::Packet::BlockChange.create(coords, RedstoneBot::ItemType::Wool.id, 6)
    expect(@chunk_tracker.block_type(coords)).to eq(RedstoneBot::ItemType::Wool)
    expect(@chunk_tracker.block_metadata(coords)).to eq(6)    
  end
  
  it "should report nil (unknown) at y > 16" do
    expect(testdata1.ground_up_continuous).to eq(false)
    #therefore, we don't actually know what is in the upper sections yet...
    (16..255).step(30).each do |y|
      expect(@chunk_tracker.block_type([42, y, 20])).to eq(nil)
      expect(@chunk_tracker.block_metadata([42,y,20])).to eq(0)
    end
  end
  
  it "handles ground-up-continuous updates" do
    testdata2 = RedstoneBot::Packet::ChunkData.create(testdata1.chunk_id, true, testdata1.primary_bit_map, testdata1.add_bit_map, data1)
    @client << testdata2
    (16..255).step(30).each do |y|
      expect(@chunk_tracker.block_type([42, y, 20])).to eq(RedstoneBot::ItemType::Air)
      expect(@chunk_tracker.block_metadata([42,y,20])).to eq(0)
    end    
  end
  
  it "handles multi-block changes" do
    expect(@chunk_tracker.chunks.size).to eq(1)
    expect(@chunk_tracker.chunks[[32,16]].instance_variable_get(:@metadata)[0].size).to be >= 2048
    
    @client << RedstoneBot::Packet::MultiBlockChange.create([
      [[42,1,23], RedstoneBot::ItemType::Piston.id, 0],
      [[42,2,23], RedstoneBot::ItemType::Piston.id, 1],
      [[42,3,23], RedstoneBot::ItemType::Piston.id, 2],
      [[42,4,23], RedstoneBot::ItemType::Piston.id, 3]
    ])
    
    (0..3).each do |i|
      expect(@chunk_tracker.block_type([42, 1+i, 23])).to eq(RedstoneBot::ItemType::Piston)
      expect(@chunk_tracker.block_metadata([42, 1+i, 23])).to eq(i)
    end
  end
  
  it "handles calls to change_block (nibble=0)" do
    @chunk_tracker.change_block([32, 0, 16], RedstoneBot::ItemType::Wool, 3)
    expect(@chunk_tracker.block_type([32, 0, 16])).to eq(RedstoneBot::ItemType::Wool)
    expect(@chunk_tracker.block_metadata([32, 0, 16])).to eq(3)
  end
  
  it "handles calls to change_block (nibble=1)" do
    @chunk_tracker.change_block([33, 0, 16], RedstoneBot::ItemType::Wool, 3)
    expect(@chunk_tracker.block_type([33, 0, 16])).to eq(RedstoneBot::ItemType::Wool)
    expect(@chunk_tracker.block_metadata([33, 0, 16])).to eq(3)
  end
  
  it "reports which chunks are loaded" do
    expect(@chunk_tracker.loaded_chunks.collect(&:id)).to eq([testdata1.chunk_id])
  end
  
  it "handles deallocation" do
    @client << RedstoneBot::Packet::ChunkData.create_deallocation([32,16])
    expect(@chunk_tracker.chunks[[32,16]]).to eq(nil)
  end
  
  it "can calculate chunk IDs" do
    expect(@chunk_tracker.chunk_id_at(RedstoneBot::Coords[-32.1, 0, -64.1])).to eq([-48, -80])
    expect(@chunk_tracker.chunk_id_at(RedstoneBot::Coords[32.1, 0, 64.1])).to eq([32, 64])
  end
  
  context "when reporting chunk changes" do
    before do
      @receiver = double("receiver")
      @chunk_tracker.on_change do |coords, packet|
        @receiver.info(coords,packet)
      end
    end
        
    it "reports chunk changes" do
      expect(@receiver).to receive(:info).with([32,16], testdata1)
      @client << testdata1
    end
    
    it "reports calls to change_block" do
      expect(@receiver).to receive(:info).with([32,16], nil)
      @chunk_tracker.change_block([32,0,16], RedstoneBot::ItemType::Wool, 3)
    end
  end
  
  context "after receiving a MapChunkBulk packet" do
    before do
      expect(bulkdata1.size).to eq(2*(10240*16 + 256))
      @client << map_chunk_bulk1
    end
    
    it "should have all three chunks loaded" do
      expect(@chunk_tracker.loaded_chunks.collect(&:id).sort).to eq([[32, 16], [48, 16], [64, 16]])
    end
    
    it "should have the new data" do
      expect(@chunk_tracker.block_type([50,1,20])).to eq(RedstoneBot::ItemType::WheatBlock)
      expect(@chunk_tracker.block_type([70,1,20])).to eq(RedstoneBot::ItemType::WheatBlock)
    end
  end
  
  context "when teleported to a new dimension with Packet::Respawn" do
    # TODO: it "unloads old chunks" do
    # @chunk_tracker.loaded_chunks.should be_empty
    #end
  end
end 