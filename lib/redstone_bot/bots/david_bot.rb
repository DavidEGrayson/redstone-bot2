require "redstone_bot/bot"

module RedstoneBot::Bots; end

class RedstoneBot::Bots::DavidBot < RedstoneBot::Bot
  def setup
    standard_setup
    
    previous_closest = nil
    @body.on_position_update do
      closest = @entity_tracker.closest_entity
      if closest != previous_closest
        @client.chat "looking at #{closest.inspect} d=%.4f" % [(closest.position - @body.position).magnitude]
        previous_closest = closest
      end
      @body.look_at @entity_tracker.closest_entity      
    end
    
    @client.listen do |p|
      case p
      when 
    end
  end
end