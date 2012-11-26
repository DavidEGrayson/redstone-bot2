module RedstoneBot
  module WindowManipulation
    def chest_open_start(coords)
      block_type = chunk_tracker.block_type(coords)
      if block_type != ItemType::Chest
        raise "Cannot open chest: #{coords} is #{block_type}."
      end
      
      selected_slot = nil
      send_packet Packet::Animation.new client.eid, 1
      send_packet Packet::PlayerBlockPlacement.new coords, 1, selected_slot, 8, 15, 8
    end
  end
end