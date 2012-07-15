require "redstone_bot/bot"

module RedstoneBot
  module Bots; end

  class Bots::DavidBot < RedstoneBot::Bot
  
    def setup
      standard_setup
      
      @body.on_position_update do
        @body.look_at @entity_tracker.closest_entity      
      end
      
      @client.listen do |p|
        case p
        when Packet::Disconnect
          exit 2
        end
      end
      
    end
    
  end
end