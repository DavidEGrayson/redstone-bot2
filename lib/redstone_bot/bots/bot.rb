require_relative 'basic_bot'

require_relative '../brain'
require_relative '../packet_printer'

require_relative '../trackers/entity_tracker'
require_relative '../trackers/chunk_tracker'
require_relative '../trackers/inventory'
require_relative '../trackers/window_tracker'

require_relative '../abilities/block_manipulation'
require_relative '../abilities/falling'
require_relative '../abilities/movement'
require_relative '../abilities/window_manipulation'

require_relative '../chat/chat_filter'
require_relative '../chat/chat_evaluator'
require_relative '../chat/chat_chunk'
require_relative '../chat/chat_inventory'
require_relative '../chat/chat_mover'

# This class is not too useful on its own.  It is meant to be subclassed by
# people making bots.
module RedstoneBot
  class Bot < BasicBot
    include Falling
    include BlockManipulation
    include WindowManipulation
    include Movement
    include ChatChunk, ChatInventory, ChatMover

    attr_reader :brain, :chunk_tracker, :entity_tracker, :inventory, :window_tracker

    # Sets up the logical connections of the different components
    # in this bot.
    def setup
      super

      @body.on_position_update do
        default_position_update
      end

      setup_brain
      @entity_tracker = EntityTracker.new(@client, @body)
      @chunk_tracker = ChunkTracker.new(@client)
      #@inventory = Inventory.new(@client)  # TODO: remove this and get FarmBot working again without it
      @window_tracker = WindowTracker.new(@client)

      @chat_printer = PacketPrinter.new(@client, [Packet::ChatMessage])

      @chat_filter = ChatFilter.new(@client)
      @chat_filter.only_player_chats
      @chat_filter.reject_from_self
      @chat_filter.aliases CHAT_ALIASES if defined?(CHAT_ALIASES)
      @chat_filter.only_from_user(MASTER) if defined?(MASTER)

      @chat_evaluator = ChatEvaluator.new(@chat_filter, self)
      @chat_evaluator.safe_level = defined?(MASTER) ? 0 : 4
      @chat_evaluator.timeout = 2

      @chat_filter.listen &method(:chat_chunk)
      @chat_filter.listen &method(:chat_inventory)
      @chat_filter.listen &method(:chat_mover)
    end

    def setup_brain
      @brain = Brain.new(self)
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
    def_delegators :@brain, :stop
    def_delegators :@chunk_tracker, :block_type, :block_metadata
    def_delegators :@inventory, :hold
    def_delegators :@entity_tracker, :entities_of_type
  end
end