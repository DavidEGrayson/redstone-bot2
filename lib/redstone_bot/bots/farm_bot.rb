require_relative 'david_bot'
require 'redstone_bot/simple_cache'

# TODO: see if we can run an IRB thing in the console instead of using ChatEvaluator

module RedstoneBot
  class Bots::FarmBot < Bots::DavidBot
  
    ExpectedWheat = 9759
    FarmBounds = [(-300..-150), (63..63), (670..800)]
  
    def setup
      super
      
      @wheat_count = SimpleCache.new(@chunk_tracker) do |chunk_id|
        count_wheat_in_chunk(chunk_id)
      end
      
      # @client.listen do |p|
        # next unless p.respond_to?(:eid)
        # Assumption: this runs AFTER entity_tracker's listen block
        # entity = @entity_tracker.entities[p.eid]
        
        # next unless ItemType::WheatItem === entity || ItemType::Seeds === entity
        
        # puts p
      # end
      
      # Caches the coordinates of each fully-grown wheat by chunk.
      @fully_grown_wheats = SimpleCache.new(@chunk_tracker) do |chunk_id|
        # TODO: reject wheats that are not in bounds
        Coords.each_in_bounds([chunk_id[0]..(chunk_id[0]+15), FarmBounds[1], chunk_id[1]..(chunk_id[1]+15)]).select do |coords|
          block_type(coords) == ItemType::WheatBlock && block_metadata(coords) == ItemType::WheatBlock.fully_grown
        end
      end
      
      #@body.on_position_update do
      #  dig_and_replant_within_reach  # OH NOES!
      #end
      
      @chat_filter.listen do |p|
        next unless p.is_a?(Packet::ChatMessage) && p.player_chat?
        
        case p.chat
        when /dig (\-?\d+) (\-?\d+)/
          # Digs a block, e.g. harvests wheat
          x, y, z = $1.to_i, FarmBounds[1].min, $2.to_i
          puts "digging #{x},#{y},#{z}!"
          dig [x,y,z]
        when /plant (\-?\d+) (\-?\d+)/
          # Plants seeds at a spot
          coords = [$1.to_i, FarmBounds[1].min-1, $2.to_i]
          if block_type(coords) == ItemType::Farmland
            puts "planting on the farmland at #{coords.inspect}!"
            if hold(ItemType::Seeds)
              place_block_above coords
            else
              chat "got seeds?"
            end
          else
            chat "dat not farm"
          end
        when "whee"
          # Harvest and replant everything          
          dig_and_replant_within_reach
        when "farm"
          farm
        when "next"
          coords = closest_fully_grown_wheat
          chat "closest fully grown wheat = #{coords.inspect}"
        end
      end
    end
    
    # Runs in a position update fiber
    def farm
      return unless require_fiber { farm }
      
      dig_and_replant_within_reach
      collect_nearby_items(10)
      
      chat "done farming I guess"
    end
    
    def dig_and_replant_within_reach
      wheats_dug = 0
      body.position.change_y(FarmBounds[1].min).spiral.first(100).each do |coords|
        if !hold(ItemType::Seeds)
          #chat "got seeds?"
          puts "got seeds?"
          break
        end
        
        if block_type(coords) == ItemType::WheatBlock && block_metadata(coords) == ItemType::WheatBlock.fully_grown
          wheats_dug += 1
          dig coords
        end
        
        ground = coords - Coords::Y
        if block_type(ground) == ItemType::Farmland && block_type(coords) == ItemType::Air
          place_block_above ground, ItemType::WheatBlock
        end
      end
      return wheats_dug
    end
    
    def dig(coords)
      puts "Digging #{coords}."
      @client.send_packet Packet::PlayerDigging.start coords
      
      # We will NOT get an update from the server about the digging finishing.
      @chunk_tracker.change_block(coords, ItemType::Air)
      
      nil
    end
    
    def place_block_above(coords, item_type)
      # TODO: remove item_type arg, calculate it from @inventory.selected_slot.item_type (e.g. WheatItem -> WheatBlock)
    
      #puts "Placing block above #{coords}."
      @client.send_packet Packet::PlayerBlockPlacement.new coords, 1, @inventory.selected_slot, 4, 15, 5
      @client.send_packet Packet::Animation.new @client.eid, 1

      # We will NOT get an update from the server about the new block
      @chunk_tracker.change_block(coords, item_type)
      
      # We WILL get a Set Slot packet from the server, but we want to keep track of the change before that happens
      @inventory.use_up_one
    end
    
    def collect_nearby_items(timeout)
      timeout(timeout) do
        while true
          item = @entity_tracker.closest_entity(Item)
          if item && distance_to(item) < 30
            puts "moving to #{item}"
            move_to item.position.change_y(FarmBounds[1].min)
          else
            return
          end
        end
      end
    end
    
    def closest_fully_grown_wheat
      fully_grown_wheats.min_by { |coords| @body.distance_to(coords) }
    end
    
    def wheat_count
      farm_chunks.inject(0) { |sum, chunk_id| sum + (@wheat_count[chunk_id] || 0) }
    end
    
    def fully_grown_wheats
      farm_chunks.flat_map { |chunk_id| @fully_grown_wheats[chunk_id] }
    end
    
    # Uncached!
    def average_growth
      growths = wheats.collect { |c| block_metadata(c) }
      growths.inject(:+).to_f / growths.count
    end
    
    # Uncached!
    def wheats
      farm_blocks.select { |c| block_type(c) == ItemType::WheatBlock }
    end
    
    # Uncached!
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