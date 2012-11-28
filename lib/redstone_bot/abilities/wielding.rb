require_relative '../empty'

# Holding: this module is mixed into the Box class to provide methods for
# keeping track of the currently-held item and holding other items from the inventory.
# It requires window_tracker and hotbar_spots.
module RedstoneBot
  module Wielding
    def wielded_spot
      # We can't call window_tracker.inventory because the inventory might not be loaded yet.
      @wielded_spot ||= inventory.hotbar_spots[0]
    end

    def wielded_item
      wielded_spot.item
    end
    
    # Drops quantity one of the item the player is holding.
    # It's like pressing q.
    def wielded_item_drop
      @client.send_packet Packet::PlayerDigging.drop
      
      # NOTE: the server will send a nice SetSlot packet after we do this, but
      # in the interrim maybe we should prepare for that be saying the inventory
      # is out of sync?
    end

    def wield(x)
      case x
      when Spot
        if x == wielded_spot
          true
        elsif inventory.hotbar_spots.include? x
          @wielded_spot = x
          client.send_packet Packet::HeldItemChange.new inventory.hotbar_spots.index(x)
          true
        elsif inventory.general_spots.include? x
          # We will need to do some clicking to get the item into the hotbar.
          # We try to put it into an empty spot, but if that is no an option then
          # we put it into the currently-wielded spot.
          hotbar_spot = inventory.hotbar_spots.empty_spots.first || wielded_spot
          window_tracker.swap hotbar_spot, x
          wield hotbar_spot
        else
          raise ArgumentError, "Cannot wield spot #{x}; move it to the inventory first."
        end
        
      when Integer
        wield inventory.hotbar_spots[x]

      when nil
        wield Empty        

      else  # Item object, ItemType object, or Empty module
        candidates = [wielded_spot] + inventory.hotbar_spots + inventory.normal_spots
        spot = candidates.find { |spot| x === spot }
        
        if spot
          wield spot
        else
          false
        end
        
      end
    end
    
  end
end