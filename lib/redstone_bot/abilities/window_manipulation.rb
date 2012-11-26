module RedstoneBot
  module WindowManipulation
    def inventory
      window_tracker.inventory
    end
    
    def dump(x)
      case x
      when Spot
        window_tracker.dump x
      else
        window = window_tracker.usable_window
        window.spots.grep(x).each { |spot| dump spot }
      end
      nil
    end
    
    def dump_all
      dump NonEmpty
    end
    
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
      yield window_tracker.chest_spots
      wait_until { window_tracker.synced? }
      window_tracker.close_window
      # TODO: do something to ignore the unneeded SetSlot packets that come after closing the window?
      
      nil
    end
  end
end