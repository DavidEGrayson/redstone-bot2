require_relative 'spec_helper'
require 'redstone_bot/chunk_tracker'
require 'zlib'

class RedstoneBot::Packet::ChunkData
  # Not included yet: :add_bit_map, :ground_up_contiguous
  
  def data=(data)
    @compressed_data = Zlib::Deflate.deflate(data)
  end
end

testdata1 = RedstoneBot::Packet::ChunkData.new
testdata1.instance_variable_set :@x, 0
testdata1.instance_variable_set :@z, 1
testdata1.instance_variable_set :@primary_bit_map, 1   # only set the y=0..15 section
data = ""
data << "\x3C" * 256   # y = 0 is all farmland
data << "\x3B" * 256   # y = 1 is all wheat
data = data.ljust(16*256, "\x00")   # the rest of the block types are air
data << "\x00" * 128   # y = 0 no metadata
data << "\x55" * 128   # y = 1 : All crops are 5 tall (7 is the max)
data = data.ljust(16*128, "\x00")   # the rest of the metadata is 0
testdata1.data = data

describe RedstoneBot::Chunk do
  before do
    @chunk = RedstoneBot::Chunk.new([0,16])    
    @chunk.apply_change testdata1
  end
  
  it "should report farmland at y = 0" do
    @chunk.block_type_id([3,0,17]).should == RedstoneBot::BlockType::Farmland.id
  end
  
  it "should report wheat at y = 1" do
    @chunk.block_type_id([10,1,20]).should == RedstoneBot::BlockType::Wheat.id
    
    @chunk.block_type_raw_yslice(1).should == "\x3B" * 256
  end
  
  it "should report metadata=5 at y=1" do
    @chunk.block_metadata([10,1,20]).should == 5
  end
  
  it "can change individual block type and metadata" do
    @chunk.set_block_type_and_metadata([10,1,20], RedstoneBot::BlockType::Wool.id, 6)
    @chunk.block_metadata([10,1,20]).should == 6
    @chunk.block_type_id([10,1,20]).should == RedstoneBot::BlockType::Wool.id
    @chunk.block_metadata([11,1,20]).should == 5
    @chunk.block_type_id([11,1,20]).should == RedstoneBot::BlockType::Wheat.id
  end
end

describe RedstoneBot::ChunkTracker do
  before do
    @client = TestClient.new
    @chunk_tracker = RedstoneBot::ChunkTracker.new(@client)
    @client << RedstoneBot::Packet::ChunkAllocation.new(testdata1.x, testdata1.z, true)
    @client << testdata1
  end
  
  it "should report farmland at y = 0" do
    @chunk_tracker.block_type([4,0,18]).should == RedstoneBot::BlockType::Farmland
  end

  it "should report wheat at y = 1" do
    @chunk_tracker.block_type(RedstoneBot::Coords[10,1,20]).should == RedstoneBot::BlockType::Wheat
  end
  
  it "should report metadata at y = 1" do
    @chunk_tracker.block_metadata([10,1,20]).should == 5
  end
  
  context "when reporting chunk changes" do
    before do
      @receiver = double("receiver")
      @chunk_tracker.on_change do |coords, packet|
        @receiver.info(coords,packet)
      end
    end
    
    it "reports chunk allocation" do
      p = RedstoneBot::Packet::ChunkAllocation.new(testdata1.x, testdata1.z, true)
      @receiver.should_receive(:info).with([0,16], p)
      @client << p
    end
    
    it "reports chunk changes" do
      @receiver.should_receive(:info).with([0,16], testdata1)
      @client << testdata1
    end
    
    it "reports chunk deallocation" do
      p = RedstoneBot::Packet::ChunkAllocation.new(testdata1.x, testdata1.z, false)
      @receiver.should_receive(:info).with([0,16], p)
      @client << p
    end
  end
end 