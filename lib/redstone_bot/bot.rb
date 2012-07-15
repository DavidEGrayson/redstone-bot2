require "redstone_bot/body"
require "redstone_bot/entity_tracker"
require "redstone_bot/chunk_tracker"

# This class is not too useful on its own.  It is meant to be subclassed by
# people making bots.
module RedstoneBot
  class Bot
    def initialize(client)
      @client = client
    end
    
    def start
      setup
      @client.start
    end
    
    # Sets up the logical connections of the different components
    # in this bot.
    def setup
      raise "setup must be defined in a subclass"
    end
    
    # Can be called by subclasses
    def standard_setup
      @body = Body.new(@client)
      @entity_tracker = EntityTracker.new(@client, @body)
    end
  end
end