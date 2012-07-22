require_relative "david_bot"

module RedstoneBot
  class Bots::FarmBot < Bots::DavidBot
  
    ExpectedWheat = 9747
    FarmBounds = [(-294..-156), (63..63), (682..797)]
  
    def setup
      super
            
      @chat_filter.listen do |p|
        next unless p.is_a?(Packet::ChatMessage) && p.player_chat?
        
        case p.chat
        when /d (\-?\d+) (\-?\d+) (\-?\d+)/
          x, y, z = $1.to_i, $2.to_i, $3.to_i
          puts "using #{x},#{y},#{z}!"
          #@client.send_packet Packet::PlayerDigging.new(2, [x, y, z], 0)
          @client.send_packet Packet::PlayerDigging.start [x,y,z]
        end
      end
      
    end
    
    def average_growth
      growths = wheats.collect { |c| block_metadata(c) }
      growths.inject(:+).to_f / growths.count
    end
    
    def wheats
      farm_blocks.select { |c| block_type(c) == BlockType::Wheat }
    end
    
    def count_wheat
      farm_blocks.count { |c| block_type(c) == BlockType::Wheat }
    end
    
    def count_unloaded
      farm_blocks.count { |c| block_type(c) == nil }
    end
    
    def farm_blocks
      Coords.each_in_bounds(FarmBounds)
    end    

  end
end