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

      else  # Slot object, ItemType object, or Empty module
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