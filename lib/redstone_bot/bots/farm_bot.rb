require_relative 'david_bot'
require 'redstone_bot/simple_cache'

# TODO: see if we can run an IRB thing in the console instead of using ChatEvaluator

module RedstoneBot
  class Bots::FarmBot < Bots::DavidBot
  
    ExpectedWheatCount = 9759
    FarmBounds = [(-300..-150), (63..63), (670..800)]
    Storage = Coords[-210, 68, 798]
    StorageWaypoint = Coords[-210, 63, 784]  # with a better pathinder we wouldn't need this
  
    def setup
      super
      
      @wheat_count = SimpleCache.new(@chunk_tracker) do |chunk_id|
        count_wheat_in_chunk(chunk_id)
      end
      
      # Caches the coordinates of each fully-grown wheat by chunk.
      @fully_grown_wheats = SimpleCache.new(@chunk_tracker) do |chunk_id|
        # TODO: reject wheats that are not in bounds
        Coords.each_in_bounds([chunk_id[0]..(chunk_id[0]+15), FarmBounds[1], chunk_id[1]..(chunk_id[1]+15)]).select do |coords|
          block_type(coords) == ItemType::WheatBlock && block_metadata(coords) == ItemType::WheatBlock.fully_grown
        end
      end
      
      @chunk_tracker.on_change do |chunk_id|
        if block_type([-254, 63, 775]) == ItemType::WheatBlock
          raise "gotcha now"
        end
        
        if wheat_count > ExpectedWheatCount
          raise "wtfbbq #{wheat_count}"
        end
      end
      
      @chat_filter.listen do |p|
        next unless p.is_a?(Packet::ChatMessage) && p.player_chat?
        
        case p.chat
        when "farm"
          farm
        end
      end
    end
    
    # Runs in a position update fiber
    def farm
      return unless require_fiber { farm }
      
      while true
        if wheat_count < ExpectedWheatCount - 50
          puts "what have I done??"
          return
        end
        
        if !inventory.include? ItemType::Seeds
          chat "got seeds?"
          return
        end
        
        # TODO: go dump your stuff unless you have room for seeds AND wheatitem
                
        wheats_dug = dig_and_replant_within_reach
        if wheats_dug > 0
          delay(0.1)   # TODO: instead of delaying, specify a MIN time for collecting nearby items because it takes a finite time for the server to notify us
          collect_nearby_items(10)   # TODO: only walk towards seeds and wheatitem
        elsif coords = closest_fully_grown_wheat
          move_to coords + Coords[0.5, 0.0, 0.5]
        end
        
        wait_for_next_position_update
      end
      
      chat "done farming"
    end
    
    def dig_and_replant_within_reach
      wheats_dug = 0
      body.position.change_y(FarmBounds[1].min).spiral.first(100).each do |coords|
        if !hold(ItemType::Seeds)
          #chat "got seeds?"
          puts "got seeds?"
          break
        end
        
        ground = coords - Coords::Y
                
        next unless distance_to(ground) < 6.2   # TODO: more carefully choose a value for this
        
        if block_type(coords) == ItemType::WheatBlock && block_metadata(coords) == ItemType::WheatBlock.fully_grown
          puts "#{time_string} digging #{coords}"
          wheats_dug += 1
          dig coords
        end
        
        if block_type(ground) == ItemType::Farmland && block_type(coords) == ItemType::Air
          puts "#{time_string} replanting #{coords}"
          place_block_above ground, ItemType::WheatBlock
          #delay(0.1)  # tmphax to slow down the farming
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
    
    def go_to_storage
      return unless require_fiber { go_to_storage }
      
      move_to StorageWaypoint if defined?(StorageWaypoint)
      path_to Storage
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
            puts "#{time_string} moving to #{item}"
            move_to item.position.change_y(FarmBounds[1].min)
          else
            return
          end
        end
      end
    end
    
    def save_wheats
      filename = "wheats.dat"
      if File.exist?(filename)
        chat "file already exist man"
        return
      end
      File.open(filename, "w") do |f|
        wheats.collect(&:to_a).sort.each do |coords|
          f.puts coords.join("\t")
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
      yrange = FarmBounds[1]
      chunk = @chunk_tracker.chunks[chunk_id]
      return nil if !chunk
      yrange.inject(0) do |sum, y|
        sum + chunk.block_type_raw_yslice(y).bytes.count(ItemType::WheatBlock.id)
      end
    end
    
  end
end