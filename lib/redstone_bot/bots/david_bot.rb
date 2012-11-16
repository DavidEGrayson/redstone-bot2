require 'redstone_bot/bots/bot'

require 'redstone_bot/chat/chat_filter'
require 'redstone_bot/chat/chat_evaluator'
require 'redstone_bot/chat/chat_chunk'
require 'redstone_bot/chat/chat_inventory'
require 'redstone_bot/chat/chat_mover'

require 'redstone_bot/abilities/pathfinder'

require 'redstone_bot/profiler'
require 'redstone_bot/packet_printer'

module RedstoneBot
  class DavidBot < RedstoneBot::Bot
    include ChatChunk, ChatInventory, ChatMover

    def setup
      super

      @chat_filter = ChatFilter.new(@client)
      @chat_filter.only_player_chats
      @chat_filter.reject_from_self
      @chat_filter.aliases CHAT_ALIASES if defined?(CHAT_ALIASES)
      @chat_filter.only_from_user(MASTER) if defined?(MASTER)

      @chat_evaluator = ChatEvaluator.new(@chat_filter, self)
      @chat_evaluator.safe_level = defined?(MASTER) ? 4 : 0
      @chat_evaluator.timeout = 2

      @chat_filter.listen &method(:chat_chunk)
      @chat_filter.listen &method(:chat_inventory)
      @chat_filter.listen &method(:chat_mover)
    end

  end
end