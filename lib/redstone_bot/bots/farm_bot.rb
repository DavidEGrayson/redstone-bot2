require_relative 'david_bot'
require 'redstone_bot/simple_cache'

module RedstoneBot
  class Bots::FarmBot < Bots::DavidBot
  
    ExpectedWheat = 9759
    FarmBounds = [(-300..-150), (63..63), (670..800)]
  
    def setup
      super
      
      @wheat_count = SimpleCache.new(@chunk_tracker) do |chunk_id|
        count_wheat_in_chunk(chunk_id)
      end
            
      @chat_filter.listen do |p|
        next unless p.is_a?(Packet::ChatMessage) && p.player_chat?
        
        case p.chat
        when /d (\-?\d+) (\-?\d+) (\-?\d+)/
          x, y, z = $1.to_i, $2.to_i, $3.to_i
          puts "using #{x},#{y},#{z}!"
          #@client.send_packet Packet::PlayerDigging.new(2, [x, y, z], 0)
          @client.send_packet Packet::PlayerDigging.start [x,y,z]
        when /g/
          @body.start do
            while true
              item = @entity_tracker.closest_entity(Item)
              if item && @body.distance_to(item) < 30
                puts "moving to #{item}"
                move_to item.position.change_y(FarmBounds[1].min)
              else
                @body.wait_for_next_position_update
              end
            end
          end
        end
      end
      
      #@entity_tracker.debug = true
      #@entity_tracker.debug_ignore = [Villager, IronGolem, Zombie, Creeper, Skeleton, Pig, Spider, Squid, Enderman, Slime, Sheep, Cow]
    end
    
    def average_growth
      growths = wheats.collect { |c| block_metadata(c) }
      growths.inject(:+).to_f / growths.count
    end
    
    def wheats
      farm_blocks.select { |c| block_type(c) == ItemType::WheatBlock }
    end
    
    def wheat_count
      farm_chunks.inject(0) { |sum, chunk_id| sum + @wheat_count[chunk_id] }
    end
    
    def count_unloaded
      farm_blocks.count { |c| block_type(c) == nil }
    end
    
    def farm_blocks
      Coords.each_in_bounds(FarmBounds)
    end
    
    def farm_chunks
      Coords.each_chunk_id_in_bounds(FarmBounds)
    end
    
    # This function has intimate knowledge of Chunk and ChunkTracker.
    # chunk_id is an [x,z] array with x and z are multiples of 16.
    def count_wheat_in_chunk(chunk_id)
      puts "COUNTING WHEAT in #{chunk_id}"
      yrange = FarmBounds[1]
      chunk = @chunk_tracker.chunks[chunk_id]
      return nil if !chunk
      yrange.inject(0) do |sum, y|
        sum + chunk.block_type_raw_yslice(y).bytes.count(ItemType::WheatBlock.id)
      end
    end
    
  end
end