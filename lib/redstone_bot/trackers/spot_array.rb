require 'redstone_bot/empty'

module RedstoneBot
  # A module that can be mixed into an Array that contains only spots
  # in order to provide some useful features.
  module SpotArray
    def self.[](*spots)
      spots.extend self
    end
    
    def empty_spots
      grep(RedstoneBot::Empty)
    end
    
    # Cannot call this count because that is already taken.
    # TODO: consider changing "count" to quantity in the Slot/Item class and everywhere else
    # make it consistent with the name of this function!
    def quantity(type)
      grep(type).inject(0){ |sum, spot| sum + spot.item.count }
    end
  end
end