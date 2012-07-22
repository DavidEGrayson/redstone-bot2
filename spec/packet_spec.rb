require 'redstone_bot/packets'

def multi_block_change(block_changes)
  block_changes = block_changes.collect do |c|
    c = RedstoneBot::Packet::BlockChange.new(*c) unless c.respond_to?(:x)
  end

  chunk_id = block_changes[0].chunk_id
  
  binary_data = [chunk_id[0]/16, chunk_id[1]/16, block_changes.size, 4*block_changes.size].pack("l>l>s>l>")
  binary_data += block_changes.collect do |c|
    [(c.x%16)+((c.z%16)<<4), c.y, (c.block_type_id<<4) + (c.block_metadata&0xF)].pack("CCs>")
  end.join
    
  RedstoneBot::Packet::MultiBlockChange.receive_data(test_stream(binary_data))
end

describe RedstoneBot::Packet::MultiBlockChange do
  it "correctly parses binary data" do
    mbc = multi_block_change([
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