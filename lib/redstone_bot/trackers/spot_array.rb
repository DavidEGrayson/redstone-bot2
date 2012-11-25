require 'redstone_bot/empty'

module RedstoneBot
  # A module that can be mixed into an Array that contains only spots
  # in order to provide some useful features.
  module SpotArray
    def self.[](*spots)
      spots.extend self
    end
    
    def empty_spots
      grep(Empty)
    end
    
    def non_empty_spots
      grep(NonEmpty)
    end
    
    # Cannot call this count because that is already taken.
    # TODO: consider changing "count" to quantity in the Slot/Item class and everywhere else
    # make it consistent with the name of this function!
    def quantity(type=NonEmpty)
      grep(type).inject(0){ |sum, spot| sum + spot.item.count }
    end
    
    def items=(items)
      raise ArgumentError, "expected #{count} items but received #{items.count}" if items.count != count
      zip(items).each do |spot, item|
        spot.item = item
      end
    end
    
    def items
      collect &:item
    end
    
  end
end