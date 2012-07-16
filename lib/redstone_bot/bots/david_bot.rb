require "redstone_bot/bot"
require "redstone_bot/chat_evaluator"

module RedstoneBot
  module Bots; end

  class Bots::DavidBot < RedstoneBot::Bot
  
    def setup
      standard_setup
      
      ce = ChatEvaluator.new(self, @client)
      #ce.only_for_username = "Elavid"
      
      @body.on_position_update do
        @body.look_at @entity_tracker.closest_entity      
      end
      
      @client.listen do |p|
        case p
        when Packet::ChatMessage
          puts p
        when Packet::Disconnect
          exit 2
        end
      end
      
    end
    
  end
end