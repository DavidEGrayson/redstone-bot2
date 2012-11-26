# Holding: this module is mixed into the Box class to provide methods for
# keeping track of the currently-held item and holding other items from the inventory.
# It requires window_tracker and hotbar_spots.
module RedstoneBot
  module Wielding
    def wielded_spot
      # We can't call window_tracker.inventory because the inventory might not be loaded yet.
      @wielded_spot ||= hotbar_spots[0]
    end

    def wielded_item
      wielded_spot.item
    end

    def wield(x)
      case x
      when Spot
        if x != wielded_spot
          index = hotbar_spots.index(x)
          if !index
            raise ArgumentError, "Cannot wield given spot because it is not in the hotbar."
          end
          @wielded_spot = x
          client.send_packet Packet::HeldItemChange.new index
        end
        true

      when Integer
        wield hotbar_spots[x]

      when Slot
        true
      when ItemType
        true
      else
        raise ArgumentError, "Don't know how to wield a #{x.class}: #{x.inspect}"
      end
    end
  end
end