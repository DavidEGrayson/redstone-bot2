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
      # TODO: throw exception if not holding an item that can be places
    
      client.send_packet Packet::PlayerBlockPlacement.new coords, 1, @inventory.selected_slot, 8, 15, 8
      client.send_packet Packet::Animation.new @client.eid, 1

      # We will NOT get an update from the server about the new block
      chunk_tracker.change_block(coords, item_type)
      
      # We WILL get a Set Slot packet from the server, but we want to keep track of the change before that happens
      inventory.use_up_one
      nil
    end
  end
end