module RedstoneBot
  module ChatChunk
    def chat_chunk(p)
      case p.chat
      when /\Ahow much (.+)\Z/
        # TODO: perhaps cache these results using a SimpleCache
        name = $1
        item_type = ItemType.from name
        if item_type.nil? && name != "nil" && name != "unloaded"
          chat "dunno what #{name} is"
          return
        end          
        
        chat "counting #{item_type && item_type.inspect || 'unloaded blocks'}..."
        result = @chunk_tracker.loaded_chunks.inject(0) do |sum, chunk|
          sum + chunk.count_block_type(item_type)
        end
        chat "there are #{result}"
      end
    end
  end
end