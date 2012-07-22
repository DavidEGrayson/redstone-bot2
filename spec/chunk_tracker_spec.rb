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
data = data.ljust(16*256 + 16*128, "\x00")   # the rest of the metadata is 0
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
  
  it "handles block changes" do
    coords = [10,1,21]
    @client << RedstoneBot::Packet::BlockChange.new(coords, RedstoneBot::BlockType::Wool.id, 6)
    @chunk_tracker.block_type(coords).should == RedstoneBot::BlockType::Wool
    @chunk_tracker.block_metadata(coords).should == 6    
  end
  
  it "handles multi-block changes" do
    @chunk_tracker.chunks.size.should == 1
    @chunk_tracker.chunks[[0,16]].instance_variable_get(:@metadata)[0].size.should >= 2048
    
  
    start_coords = [10, 1, 23]
    binary_data = [0, 1, 3, 4*4].pack("l>l>s>l>")
    binary_data += (0..3).collect do |i|
      [(start_coords[0]%16)+((start_coords[2]%16)<<4), start_coords[1]+i, (RedstoneBot::BlockType::Piston.id<<4) + i].pack("CCs>")
    end.join
    puts "binary_data = #{binary_data.bytes.to_a.inspect}"
    mbc = RedstoneBot::Packet::MultiBlockChange.receive_data(test_stream(binary_data))
    
    mbc.to_enum.to_a.should == [
      [[10,1,7], RedstoneBot::BlockType::Piston.id, 0],
      [[10,2,7], RedstoneBot::BlockType::Piston.id, 1],
      [[10,3,7], RedstoneBot::BlockType::Piston.id, 2],
      [[10,4,7], RedstoneBot::BlockType::Piston.id, 3],
    ]
    
    @client << mbc
    (0..3).each do |i|
      @chunk_tracker.block_type([10, 1+i, 23]).should == RedstoneBot::BlockType::Piston
      @chunk_tracker.block_metadata([10, 1+i, 23]).should == i
    end
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