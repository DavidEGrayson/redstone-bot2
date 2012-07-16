require 'zlib'
require 'stringio'

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
      # The block type array has 16 sections.
      # Each section has 4096 bytes, one byte per block, ordered by x,z,y.
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
      data = StringIO.new(data_string)
      
      # Loop over each 16x16x16 section in the 16x256x16 chunk.
      (0..15).each do |i|
        # Skip if this is section is not included in the change.
        next unless (p.primary_bit_map >> i & 1) == 1
        
        @block_type[i] = data.read(16*16*16)
      end
      
      # TODO some day: also store the block metadata array, block light array, sky light array, and biome array
    end
    
    # coords is an array of integers [x,y,z] in the standard world coordinate system.
    # No bounds checking is done here.
    def block_type(coords)
      section_num, section_y = coords[1].divmod 16
      section_x = coords[0] % 16
      section_z = coords[2] % 16
      
      offset = 256*section_y + 16*section_z + section_x
      
      #puts "tmphax #{section_num},#{section_y} #{section_x} #{section_z}"
      
      @block_type[section_num][offset].ord
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
    
    # coords is an array of integers [x,y,z] in the standard world coordinate system
    def block_type(coords)
      chunk_coords = [coords[0].to_i/16*16, coords[2].to_i/16*16]
      chunk = @chunks[chunk_coords]
      chunk && chunk.block_type(coords)
    end

    protected
    def allocate_chunk(chunk_coords)
      unload_chunk chunk_coords    # make sure the state stays consistent
      
      @chunks[chunk_coords] = Chunk.new(chunk_coords)
    end
    
    def unload_chunk(chunk_coords)
      chunk = @chunks.delete(chunk_coords)
      chunk.unload if chunk
    end
  end
  
end