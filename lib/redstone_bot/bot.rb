require_relative 'body'
require_relative 'entity_tracker'
require_relative 'chunk_tracker'
require_relative 'uninspectable'

# This class is not too useful on its own.  It is meant to be subclassed by
# people making bots.
module RedstoneBot
  class Bot
    include Uninspectable
  
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
      @chunk_tracker = ChunkTracker.new(@client)
    end
  end
end