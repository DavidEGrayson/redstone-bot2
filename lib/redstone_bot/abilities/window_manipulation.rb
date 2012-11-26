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
    
    def chest_open(coords, &block)
      return unless require_brain { chest_open(coords, &block) }
    
      chest_open_start(coords)
      wait_until { window_tracker.chest_spots }
      begin
        yield window_tracker.chest_spots
      ensure
        window_tracker.close_window
      end
    end
  end
end