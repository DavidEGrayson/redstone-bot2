require 'redstone_bot/bots/bot'

require 'redstone_bot/chat/chat_filter'
require 'redstone_bot/chat/chat_evaluator'
require 'redstone_bot/chat/chat_mover'
require 'redstone_bot/chat/chat_inventory'
require 'redstone_bot/chat/chat_chunk'

require 'redstone_bot/abilities/pathfinder'
require 'redstone_bot/abilities/body_movers'

require 'redstone_bot/profiler'
require 'redstone_bot/packet_printer'

module RedstoneBot
  class DavidBot < RedstoneBot::Bot
    include BodyMovers
    include Profiler
    include ChatInventory, ChatChunk

    def setup
      super
      
      @chat_filter = ChatFilter.new(@client)
      @chat_filter.only_player_chats
      @chat_filter.reject_from_self      
      @chat_filter.aliases CHAT_ALIASES if defined?(CHAT_ALIASES)
      @chat_filter.only_from_user(MASTER) if defined?(MASTER)
      
      @ce = ChatEvaluator.new(@chat_filter, self)
      @ce.safe_level = defined?(MASTER) ? 4 : 0
      @ce.timeout = 2
      @cm = ChatMover.new(@chat_filter, self, @entity_tracker)
      
      @chat_filter.listen &method(:chat_inventory)
      @chat_filter.listen &method(:chat_chunk)      
    end
    
    def standing_on
      coord_array = (@body.position - Coords::Y*0.5).to_a.collect &:floor
      "#{block_type coord_array} #{@body.position.y}->#{coord_array[1]}"
    end

  end
end