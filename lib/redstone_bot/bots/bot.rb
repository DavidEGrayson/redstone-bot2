require_relative 'basic_bot'
require_relative '../trackers/entity_tracker'
require_relative '../trackers/chunk_tracker'
require_relative '../trackers/inventory'
#require_relative '../trackers/window_tracker'
require_relative '../brain'
require_relative '../abilities/block_manipulation'
require_relative '../abilities/falling'
require_relative '../abilities/body_movers'

require 'forwardable'

# This class is not too useful on its own.  It is meant to be subclassed by
# people making bots.
module RedstoneBot
  class Bot < BasicBot
    include Falling
    include BlockManipulation
    include BodyMovers
    
    attr_reader :brain, :chunk_tracker, :entity_tracker, :inventory    
    
    # Sets up the logical connections of the different components
    # in this bot.
    def setup
      super

      @body.on_position_update do
        default_position_update
      end
      
      @brain = Brain.new(self)
      @entity_tracker = EntityTracker.new(@client, @body)
      @chunk_tracker = ChunkTracker.new(@client)
      @inventory = Inventory.new(@client)
      #@window_tracker = WindowTracker.new(@client)      
      
    end
    
    def default_position_update
      if !body.busy?
        fall_update
        look_at entity_tracker.closest_entity
      end
    end
        
    def standing_on
      coord_array = (body.position - Coords::Y*0.5).to_a.collect &:floor
      "#{block_type coord_array} #{body.position.y}->#{coord_array[1]}"
    end
    
    def_delegator :@brain, :require, :require_brain
    def_delegators :@chunk_tracker, :block_type, :block_metadata
    def_delegators :@inventory, :hold
    def_delegators :@entity_tracker, :entities_of_type
  end
end