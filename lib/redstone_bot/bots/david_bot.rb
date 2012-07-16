require "redstone_bot/bot"
require "redstone_bot/chat_evaluator"
require 'forwardable'

module RedstoneBot
  module Bots; end

  class Bots::DavidBot < RedstoneBot::Bot
    extend Forwardable
    
    def setup
      standard_setup
      
      ce = ChatEvaluator.new(self, @client)
      #ce.only_for_username = "Elavid"
      #ce.safe_level = 3
      
      @body.on_position_update do
        @body.look_at @entity_tracker.closest_entity      
      end
      
      @client.listen do |p|
        case p
        when Packet::ChatMessage
          if p.message == "<Elavid> t"
            chat "t: " + bt([98,72,239]).inspect
          end
        
          puts p
        when Packet::Disconnect
          exit 2
        end
      end      
      
    end

    def_delegator :@chunk_tracker, :block_type, :bt
    def_delegator :@client, :chat, :chat
  end
end