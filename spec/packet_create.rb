require "redstone_bot/protocol/packets"
require "redstone_bot/protocol/slot"

$e = Object.new.extend(RedstoneBot::DataEncoder)

module RedstoneBot
  def (Packet::BlockChange).create(coords, block_type_id, block_metadata)
    p = receive_data test_stream (coords + [block_type_id, block_metadata]).pack('l>Cl>S>C')
  end
  
  def (Packet::MultiBlockChange).create(block_changes)
    block_changes = block_changes.collect do |c|
      c = RedstoneBot::Packet::BlockChange.create(*c) unless c.respond_to?(:x)
    end

    chunk_id = block_changes[0].chunk_id
  
    binary_data = [chunk_id[0]/16, chunk_id[1]/16, block_changes.size, 4*block_changes.size].pack("l>l>S>l>")
    binary_data += block_changes.collect do |c|
      [(c.z%16)+((c.x%16)<<4), c.y, (c.block_type_id<<4) + (c.block_metadata&0xF)].pack("CCs>")
    end.join
    
    receive_data test_stream binary_data
  end
  
  def (Packet::ChunkData).create(chunk_id, ground_up_continuous, primary_bit_map, add_bit_map, data)
    compressed = Zlib::Deflate.deflate(data)
    binary_data = [chunk_id[0]/16, chunk_id[1]/16,
      ground_up_continuous ? 1 : 0,
      primary_bit_map, add_bit_map,
      compressed.size
    ].pack("l>l>CS>S>l>") + compressed
    receive_data test_stream binary_data
  end
  
  def (Packet::ChunkData).create_deallocation(chunk_id)
    receive_data test_stream [chunk_id[0]/16,chunk_id[1]/16,1,0,0,12].pack("l>l>CS>S>l>") + "\x78\x9C\x63\x64\x1C\xD9\x00\x00\x81\x80\x01\x01"
  end
  
  def (RedstoneBot::Packet::MapChunkBulk).create(metadata, data)
    binary_metadata = metadata.collect do |chunk_id, primary_bit_map, add_bit_map|
      [chunk_id[0]/16, chunk_id[1]/16, primary_bit_map, add_bit_map].pack("l>l>S>S>")
    end.join
    compressed_data = Zlib::Deflate.deflate(data)
    
    receive_data test_stream [metadata.size, compressed_data.size].pack("S>L>") + compressed_data + binary_metadata
  end
  
  def (Packet::SpawnDroppedItem).create(eid, slot, coords, yaw=0, pitch=0, roll=0)
    binary_data = [eid].pack("l>") + Slot.encode_data(slot) + 
     [(coords[0]*32).round, (coords[1]*32).round, (coords[2]*32).round,
     yaw, pitch, roll
    ].pack("l>l>l>ccc")
    receive_data test_stream binary_data
  end
  
  def (Packet::SpawnMob).create(eid, type, coords, yaw, pitch, head_yaw, velocity=Coords[0,0,0], metadata="\x7F")
    binary_data = [eid, type.to_i, (coords[0]*32).round, (coords[1]*32).round, (coords[2]*32).round,
      yaw.to_i, pitch.to_i, head_yaw.to_i,
      (velocity[2]*32).round, (velocity[0]*32).round, (velocity[1]*32).round
      ].pack("l>Cl>l>l>cccs>s>s>") + metadata
    receive_data test_stream binary_data
  end
  
  def (Packet::SpawnNamedEntity).create(eid, player_name, coords, yaw=0, pitch=0, current_item=0, metadata="\x7F")
    binary_data = $e.int(eid) + $e.string(player_name) + $e.int((coords[0]*32).floor) + $e.int((coords[1]*32).floor) + $e.int((coords[2]*32).floor) +
    $e.byte(yaw) + $e.byte(pitch) + $e.short(current_item) + metadata
    receive_data test_stream binary_data
  end
  
  def (Packet::DestroyEntity).create(eids)
    receive_data test_stream [eids.size].pack("C") + eids.collect { |e| [e].pack("l>") }.join
  end
  
  def (Packet::SetWindowItems).create(window_id, slots)
    binary_data = [window_id, slots.size].pack("CS>")
    binary_data += slots.collect { |slot| Slot.encode_data(slot) }.join
    receive_data test_stream binary_data
  end
  
  def (Packet::SetSlot).create(window_id, slot_id, slot)
    receive_data test_stream [window_id, slot_id].pack("CS>") + Slot.encode_data(slot)
  end
end
