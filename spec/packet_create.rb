require "redstone_bot/packets"

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
  
  def (Packet::SpawnMob).create(eid, type, coords, yaw, pitch, head_yaw, metadata="\x7F")
    binary_data = [eid, type.to_i, (coords[0]*32).round, (coords[1]*32).round, (coords[2]*32).round,
      yaw.to_i, pitch.to_i, head_yaw.to_i].pack("l>Cl>l>l>ccc") + metadata
    receive_data test_stream binary_data
  end
  
  def (Packet::SetWindowItems).create(window_id, slots_data)
    binary_data = [window_id, slots_data.size].pack("CS>")
    slots_data.collect do |slot|
      if slot
        binary_data += [slot[:item_id], slot[:count], slot[:damage]].pack("s>CS>")
        if DataReader::ENCHANTABLE.include?(slot[:item_id])
          enchant_data = slot[:enchant_data].to_s
          binary_data += [enchant_data.size].pack("S>") + enchant_data
        end
      else
        binary_data += [-1].pack("s>")
      end
    end
    receive_data test_stream binary_data
  end
end
