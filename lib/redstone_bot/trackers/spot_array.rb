module RedstoneBot
  # A module that can be mixed into an Array that contains only spots
  # in order to provide some useful features.
  module SpotArray
    def self.[](*spots)
      spots.extend self
    end
    
  end
end