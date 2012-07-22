require_relative 'spec_helper'
require 'redstone_bot/chunk_tracker'
require 'zlib'

class TestChunkData < Struct.new(:x, :z, :primary_bit_map, :compressed_data)
  # Not included yet: :add_bit_map, :ground_up_contiguous
  
  def data=(data)
    self.compressed_data = Zlib::Deflate.deflate(data)
  end
end

describe RedstoneBot::Chunk do
  before do
    @ct = RedstoneBot::Chunk.new([0,16])
    
    p = TestChunkData.new
    p.x = 0
    p.z = 16
    p.primary_bit_map = 1   # only set the y=0..15 section
    
    data = ""
    # Block types
    data << "\x3C" * 256   # y = 0 is all farmland
    data << "\x3B" * 256   # y = 1 is all wheat
    data = data.ljust(16*256, "\x00")   # the rest is air
    
    # Metadata
    data << "\x00" * 128   # y = 0 no metadata
    data << "\x55" * 128   # y = 1 : All crops are 5 tall (7 is the max)
    data = data.ljust(16*128, "\x00")   # the rest is 0
    
    p.data = data
    
    @ct.apply_change p
  end
  
  it "should have farmland at y = 0" do
    @ct.block_type_id([3,0,17]).should == RedstoneBot::BlockType::Farmland.id
  end
  
  it "should have wheat at y = 1" do
    @ct.block_type_id([10,1,20]).should == RedstoneBot::BlockType::Wheat.id
    @ct.block_metadata([10,1,20]).should == 5
  end
end