require 'zlib'
require 'stringio'
require_relative 'block_types'
require_relative 'uninspectable'

module RedstoneBot
  class Chunk
    include Uninspectable
  
    Size = [16, 256, 16]  # x,y,z size of each chunk

    NullSection = "\x00"*(16*16*16)
    NullSection.freeze

    attr_reader :coords   # array of integers [x, z]

    def initialize(coords)
      @coords = coords
      @unloaded = false
      
      # 1 byte per block, 4096 bytes per section
      # The block type array has 16 sections.
      # Each section has 4096 bytes, one byte per block, ordered by x,z,y.
      @block_type = [NullSection]*16
      @metadata = [NullSection]*16
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
      case p
      when Packet::ChunkData
        apply_broad_change(p)
      when Packet::BlockChange
        apply_block_change(p)
      when Packet::MultiBlockChange
        apply_multi_block_change(p)
      end
    end  
      
    def apply_broad_change(p)
      data_string = Zlib::Inflate.inflate(p.compressed_data)      
      data = StringIO.new(data_string)

      included_sections = (0..15).select { |i| (p.primary_bit_map >> i & 1) == 1 }
      
      included_sections.each { |i| @block_type[i] = data.read(16*16*16) }
      included_sections.each { |i| @metadata[i] = data.read(16*16*8) }
    end
    
    def apply_block_change(p)
      set_block_type_and_metadata [p.x, p.y, p.z], p.block_type, p.block_metadata
    end
    
    def apply_multi_block_change(p)
      raise "multi-block change is not implemented yet"
      p.each do |x|
      end
    end

    def convert_coords(coords)
      section_num, section_y = coords[1].divmod 16
      section_x = coords[0] % 16
      section_z = coords[2] % 16
      [section_num, section_x, section_y, section_z]
    end
    
    # coords is an array of integers [x,y,z] in the standard world coordinate system.
    # No bounds checking is done here.
    def block_type_id(coords)
      section_num, section_x, section_y, section_z = convert_coords(coords)
      offset = 256*section_y + 16*section_z + section_x
      @block_type[section_num][offset].ord
    end
    
    def block_metadata(coords)
      section_num, section_x, section_y, section_z = convert_coords(coords)
      offset = 128*section_y + 8*section_z + section_x/2
      @metadata[section_num][offset].ord >> ((section_x % 2) * 4) & 0x0F
    end
        
    def block_type_raw_yslice(y)
      section_num, section_y = y.divmod 16
      @block_type[section_num][256*section_y, 256]
    end
    
    def set_block_type_and_metadata(coords, block_type, metadata)
      section_num, section_x, section_y, section_z = convert_coords(coords)
      
      block_type_offset = 256*section_y + 16*section_z + section_x
      @block_type[section_num][block_type_offset] = block_type.chr
      
      metadata_offset = 128*section_y + 8*section_z + section_x/2
      nibble = section_x % 1
      @metadata[section_num][metadata_offset] = if nibble == 1
        (@metadata[section_num][metadata_offset].ord & 0x0F) | (metadata << 4 & 0xF0)
      else
        (@metadata[section_num][metadata_offset].ord & 0xF0) | (metadata & 0xF)
      end.chr
      # Please excuse our mess.
    end
  end

  class ChunkTracker
    include Uninspectable
  
    attr_reader :chunks
  
    def initialize(client)
      @change_listeners = []
      @chunks = {}

      client.listen do |p|
        #case p
        #when Packet::ChunkAllocation, Packet::ChunkData, Packet::MultiBlockChange, Packet::BlockChange
        #  puts Time.now.strftime("%M:%S.%L") + " " + p.inspect
        #end

        # TODO: clean this up
        case p
        when Packet::ChunkAllocation
          coords = [p.x*16, p.z*16]
          if p.mode
            allocate_chunk coords
          else
            unload_chunk coords
          end
          notify_change_listeners coords, p
        when Packet::ChunkData, Packet::MultiBlockChange
          coords = [p.x*16, p.z*16]
          chunk = @chunks[coords]
          if chunk
            @chunks[coords].apply_change p
          else
            $stderr.puts "warning: received update for a chunk that is not loaded: #{coords.inspect}"
          end
          notify_change_listeners coords, p
        when Packet::BlockChange
          coords = [p.x/16*16, p.z/16*16]
          chunk = @chunks[coords]
          if chunk
            @chunks[coords].apply_block_change p
          else
            $stderr.puts "warning: received update for a chunk that is not loaded: #{coords.inspect}"
          end
          notify_change_listeners coords, p          
        end
      end
    end

    # coords is a RedstoneBot::Coords object or an array of numbers
    def block_type(coords)
      coords = coords.collect &:floor   # make array of ints

      return BlockType::Air if coords[1] > 255   # treat spots above the top of the world as air
      return BlockType::Bedrock if coords[1] < 0 # treat spots below the top of the world as bedrock
      
      chunk = chunk_from_coords(coords)
      chunk && BlockType.from_id(chunk.block_type_id(coords))
    end
    
    def block_metadata(coords)
      coords = coords.collect &:floor
      return 0 if coords[1] > 255 || coords[1] < 0
      chunk = chunk_from_coords(coords)
      chunk && chunk.block_metadata(coords)
    end
    
    # coords is an array of INTEGERS [x,z]
    def chunk_from_coords(coords)
      c = [coords[0]/16*16, coords[2]/16*16]
      @chunks[[coords[0]/16*16, coords[2]/16*16]]
    end
    
    def on_change(&proc)
      @change_listeners << proc
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
    
    def notify_change_listeners(*args)
      @change_listeners.each do |l|
        l.call(*args)
      end
    end
  end

end