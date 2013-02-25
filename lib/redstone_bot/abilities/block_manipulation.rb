module RedstoneBot
  module BlockManipulation
    def dig(coords)
      # TODO: support digging blocks that take more than one packet to dig
    
      client.send_packet Packet::PlayerDigging.start coords
      
      # We will NOT get an update from the server about the digging finishing.
      chunk_tracker.change_block(coords, ItemType::Air)
      
      nil
    end
    
    def place_block_above(coords, item_type)
      # TODO: remove item_type arg, calculate it from @inventory.selected_slot.item_type (e.g. Seeds -> WheatBlock)
      # TODO: throw exception if not holding an item that can be placed
    
      client.send_packet Packet::PlayerBlockPlacement.new coords, 1, wielded_spot.item
      send_animation 1

      # We will NOT get an update from the server about the new block
      chunk_tracker.change_block(coords + Coords::Y, item_type)
      
      # We WILL get a Set Slot packet from the server, but we want to keep track of the change before that happens
      wielded_spot.item -= 1
      nil
    end
    
    def place_block_below(coords, item_type)
      client.send_packet Packet::PlayerBlockPlacement.new coords, 0, wielded_spot.item
      send_animation 1
      chunk_tracker.change_block(coords - Coords::Y, item_type)
      wielded_spot.item -= 1
      nil
    end
    
    def send_animation(id)
      client.send_packet Packet::Animation.new @client.eid, id
    end
  end
end