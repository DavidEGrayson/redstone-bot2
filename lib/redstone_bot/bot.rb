require "forwardable"
require_relative "uninspectable"
require_relative "body"
require_relative "entity_tracker"
require_relative "chunk_tracker"
require_relative "inventory"

# This class is not too useful on its own.  It is meant to be subclassed by
# people making bots.
module RedstoneBot
  class Bot
    include Uninspectable
    extend Forwardable
    
    attr_reader :body, :chunk_tracker, :entity_tracker, :inventory    
  
    def initialize(client)
      @client = client
    end
    
    def start_bot
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
      @inventory = Inventory.new(@client)
    end
    
    def_delegators :@body, :position, :look_at, :distance_to
    def_delegators :@chunk_tracker, :block_type, :block_metadata
    def_delegators :@client, :chat, :time_string
    def_delegators :@inventory, :hold
    def_delegators :@entity_tracker, :closest_entity
  end
end