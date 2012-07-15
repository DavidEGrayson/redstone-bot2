require 'zlib'

module RedstoneBot
  attr_reader :chunks

  class Block
    attr_reader :chunk
    attr_reader :coords   # array of integers [x,y,z]    
    
    def initialize(chunk,coords)
      @coords = coords
      @chunk = chunk
    end
    
    def x
      @coords[0]
    end
    
    def y
      @coords[1]
    end
    
    def z
      @coords[2]
    end
  end
  
  class Chunk
    Size = [16, 256, 16]  # x,y,z size of each chunk
    
    AirBlockSection = "\x00"*(16*16*16)
    
    attr_reader :coords   # array of integers [x, z]
    
    def initialize(coords)
      x, z = @coords = coords
      @unloaded = false
      
      # 1 byte per block, 4096 bytes per section
      @block_type = [AirBlockSection]*16
    end
    
    def x
      @coords[0]
    end
    
    def z
      @coords[1]
    end
    
    def unload
      @unloaded = true
    end
    
    def apply_change(p)
      data_string = Zlib::Inflate.inflate(p.compressed_data)
      data = StringIO.new(data)string)
      
      # Loop over each 16x16x16 section in the 16x256x16 chunk.
      (0..15).each do |i|
        # Skip if this is section is not included in the change.
        next unless (p.primary_bit_map >> i & 1) == 1
        
        block_types[i] = data.read(16*16*16)
        
      end
    end
  end
  
  class ChunkTracker
    def initialize(client)
      @chunks = {}
    
      client.listen do |p|
        #case p
        #when Packet::ChunkAllocation, Packet::ChunkData, Packet::MultiBlockChange, Packet::BlockChange
        #  puts Time.now.strftime("%M:%S.%L") + " " + p.inspect
        #end
        
        case p
        when Packet::ChunkAllocation
          coords = [p.x*16, p.z*16]
          if p.mode
            allocate_chunk coords
          else
            unload_chunk coords
          end
        when Packet::ChunkData
          coords = [p.x*16, p.z*16]
          @chunks[coords].apply_change p
        end
      end
    end

    protected
    def allocate_chunk(chunk_coords)
      remove_chunk chunk_coords    # make sure the state stays consistent
      
      @chunks[chunk_coords] = Chunk.new(chunk_coords)
    end
    
    def unload_chunk(chunk_coords)
      @chunks.delete(chunk_coords).unload
    end
  end
  
end