require_relative 'spec_helper'
require 'redstone_bot/chunk_tracker'
require 'zlib'

class RedstoneBot::ChunkTracker
  # Raise an exception instead of just printing to stderr: make it easier to debug
  def handle_update_for_unloaded_chunk(chunk_id)
    raise "Received update for unloaded chunk at #{chunk_id.inspect}"
  end
end
  
bt = ""
bt << "\x3C" * 256   # y = 0 is all farmland
bt << "\x3B" * 256   # y = 1 is all wheat
bt = bt.ljust(16*256, "\x00")   # the rest of the block types are air
metadata = ""
metadata << "\x00" * 128   # y = 0 no metadata
metadata << "\x55" * 128   # y = 1 : All crops are 5 tall (7 is the max)
metadata = metadata.ljust(16*128, "\x00")   # the rest of the metadata is 0
data = bt + metadata
testdata1 = RedstoneBot::Packet::ChunkData.create([32,16], false, 1, 0, data)

describe RedstoneBot::Chunk do
  before do
    @chunk = RedstoneBot::Chunk.new([32,16])    
    @chunk.apply_change testdata1
  end
  
  it "should report farmland at y = 0" do
    @chunk.block_type_id([35,0,17]).should == RedstoneBot::ItemType::Farmland.id
  end
  
  it "should report wheat at y = 1" do
    @chunk.block_type_id([42,1,20]).should == RedstoneBot::ItemType::WheatBlock.id
    
    @chunk.block_type_raw_yslice(1).should == "\x3B" * 256
  end
  
  it "should report metadata=5 at y=1" do
    @chunk.block_metadata([42,1,20]).should == 5
  end
  
  it "can change individual block type and metadata" do
    @chunk.set_block_type_and_metadata([42,1,20], RedstoneBot::ItemType::Wool.id, 6)
    @chunk.block_metadata([42,1,20]).should == 6
    @chunk.block_type_id([42,1,20]).should == RedstoneBot::ItemType::Wool.id
    @chunk.block_metadata([43,1,20]).should == 5
    @chunk.block_type_id([43,1,20]).should == RedstoneBot::ItemType::WheatBlock.id
  end
  
  it "can count blocks by type" do
    @chunk.count_block_type(RedstoneBot::ItemType::Wool).should == 0
    @chunk.count_block_type(RedstoneBot::ItemType::Farmland).should == 256
    @chunk.count_block_type(RedstoneBot::ItemType::WheatBlock).should == 256
    @chunk.count_block_type(RedstoneBot::ItemType::Air).should == 14*256
    @chunk.count_block_type(nil).should == 15*16*256    
  end
end

describe RedstoneBot::ChunkTracker do
  before do
    @client = TestClient.new
    @chunk_tracker = RedstoneBot::ChunkTracker.new(@client)
    @client << RedstoneBot::Packet::ChunkAllocation.create(testdata1.chunk_id, true)
    @client << testdata1
  end
  
  it "should report farmland at y = 0" do
    @chunk_tracker.block_type([36,0,18]).should == RedstoneBot::ItemType::Farmland
  end

  it "should report wheat at y = 1" do
    @chunk_tracker.block_type(RedstoneBot::Coords[42,1,20]).should == RedstoneBot::ItemType::WheatBlock
  end
  
  it "should report metadata at y = 1" do
    @chunk_tracker.block_metadata([42,1,20]).should == 5
  end
  
  it "handles block changes" do
    coords = [42,1,21]
    @client << RedstoneBot::Packet::BlockChange.create(coords, RedstoneBot::ItemType::Wool.id, 6)
    @chunk_tracker.block_type(coords).should == RedstoneBot::ItemType::Wool
    @chunk_tracker.block_metadata(coords).should == 6    
  end
  
  it "should report nil (unknown) at y > 16" do
    testdata1.ground_up_continuous.should == false
    #therefore, we don't actually know what is in the upper sections yet...
    (16..255).step(30).each do |y|
      @chunk_tracker.block_type([42, y, 20]).should == nil
      @chunk_tracker.block_metadata([42,y,20]).should == 15
    end
  end
  
  it "handles ground-up-continuous updates" do
    testdata2 = RedstoneBot::Packet::ChunkData.create(testdata1.chunk_id, true, testdata1.primary_bit_map, testdata1.add_bit_map, data)
    @client << testdata2
    (16..255).step(30).each do |y|
      @chunk_tracker.block_type([42, y, 20]).should == RedstoneBot::ItemType::Air
      @chunk_tracker.block_metadata([42,y,20]).should == 0
    end    
  end
  
  it "handles multi-block changes" do
    @chunk_tracker.chunks.size.should == 1
    @chunk_tracker.chunks[[32,16]].instance_variable_get(:@metadata)[0].size.should >= 2048
    
    @client << RedstoneBot::Packet::MultiBlockChange.create([
      [[42,1,23], RedstoneBot::ItemType::Piston.id, 0],
      [[42,2,23], RedstoneBot::ItemType::Piston.id, 1],
      [[42,3,23], RedstoneBot::ItemType::Piston.id, 2],
      [[42,4,23], RedstoneBot::ItemType::Piston.id, 3]
    ])
    
    (0..3).each do |i|
      @chunk_tracker.block_type([42, 1+i, 23]).should == RedstoneBot::ItemType::Piston
      @chunk_tracker.block_metadata([42, 1+i, 23]).should == i
    end
  end
  
  it "reports which chunks are loaded" do
    @chunk_tracker.loaded_chunks.collect(&:id).should == [testdata1.chunk_id]
  end
  
  context "when reporting chunk changes" do
    before do
      @receiver = double("receiver")
      @chunk_tracker.on_change do |coords, packet|
        @receiver.info(coords,packet)
      end
    end
    
    it "reports chunk allocation" do
      p = RedstoneBot::Packet::ChunkAllocation.create(testdata1.chunk_id, true)
      @receiver.should_receive(:info).with([32,16], p)
      @client << p
    end
    
    it "reports chunk changes" do
      @receiver.should_receive(:info).with([32,16], testdata1)
      @client << testdata1
    end
    
    it "reports chunk deallocation" do
      p = RedstoneBot::Packet::ChunkAllocation.create(testdata1.chunk_id, false)
      @receiver.should_receive(:info).with([32,16], p)
      @client << p
    end

  end
end 