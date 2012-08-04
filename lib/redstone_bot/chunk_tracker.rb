# Definitions:
# Chunk = 16x256x16
# Section = 16x16x16 

require 'stringio'
require_relative 'item_types'
require_relative 'uninspectable'

module RedstoneBot
  class Chunk
    include Uninspectable
  
    Size = [16, 256, 16]  # x,y,z size of each chunk

    DefaultBlockTypeIdData = ("\xFF"*(16*16*16)).freeze
    DefaultMetadata = DefaultLightData = DefaultSkyLightData = ("\x00"*(8*16*16)).freeze
    DefaultBiome = "\x00"*(16*16)
    
    AirBlockTypeIdData = ("\x00"*(16*16*16)).freeze
    AirMetadata = DefaultMetadata
    
    # Assumption: is not sent because it has all air, then sky_light = 0xF and light = 0
    AirLightData = DefaultMetadata
    AirSkyLightData = ("\xFF"*(8*16*16)).freeze
    
    attr_reader :id   # array of integers [x, z], e.g. [32,16]

    def initialize(chunk_id)
      @id = chunk_id
      @unloaded = false
      
      # 1 byte per block, 4096 bytes per section
      # The block type array has 16 sections.
      # Each section has 4096 bytes, one byte per block, ordered by x,z,y.
      # The default value of the block_type_id is \xFF, which results in a block_type of nil instead of ItemType::Air.
      # The default value of the metadata doesn't matter too much because block_type will be 0xFF before the metadata is set for the first time
      @block_type = 16.times.collect { DefaultBlockTypeIdData.dup }
      @metadata = 16.times.collect { DefaultMetadata.dup }
      @light = 16.times.collect { DefaultLightData.dup }
      @sky_light = 16.times.collect { DefaultSkyLightData.dup }
      @biome = DefaultBiome.dup
    end

    def x
      @id[0]
    end

    def z
      @id[1]
    end

    def unload
      @unloaded = true
    end

    def apply_packet(p)
      case p
      when Packet::ChunkData
        apply_broad_change p.ground_up_continuous, p.primary_bit_map, p.add_bit_map, StringIO.new(p.data)
      when Packet::BlockChange
        apply_block_change p
      when Packet::MultiBlockChange
        apply_multi_block_change p
      end
    end  
      
    def apply_broad_change(ground_up_continuous, primary_bit_map, add_bit_map, stream)
      raise "sorry, dunno about add_bit_map yet" if add_bit_map != 0

      included_sections = (0..15).select { |i| (primary_bit_map >> i & 1) == 1 }
      
      # WARNING: If not enough data is provided in the packet then the code below
      # could set some data sections to be short strings or nil.  We could pretty easily
      # check for that, but it's probably not worht the CPU time.
      included_sections.each { |i| @block_type[i] = stream.read(16*16*16) or raise }
      included_sections.each { |i| @metadata[i] = stream.read(8*16*16) or raise }
      included_sections.each { |i| @light[i] = stream.read(8*16*16) or raise }
      included_sections.each { |i| @sky_light[i] = stream.read(8*16*16) or raise }
      
      if ground_up_continuous
        other_sections = (0..15).to_a - included_sections
        other_sections.each do |i|
          @block_type[i] = AirBlockTypeIdData.dup
          @metadata[i] = AirMetadata.dup
          @light[i] = AirLightData.dup
          @sky_light[i] = AirSkyLightData.dup
        end
      end
      
      @biome = stream.read(16*16)
    end
    
    def apply_block_change(p)
      set_block_type_and_metadata [p.x, p.y, p.z], p.block_type, p.block_metadata
    end
    
    def apply_multi_block_change(p)
      p.each do |coords, block_type_id, metadata|
        set_block_type_and_metadata coords, block_type_id, metadata
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
      get_nibble @metadata, coords      
    end
    
    def light(coords)
      get_nibble @light, coords
    end

    def sky_light(coords)
      get_nibble @sky_light, coords
    end
    
    def block_type_raw_yslice(y)
      section_num, section_y = y.divmod 16
      @block_type[section_num][256*section_y, 256]
    end
    
    def set_block_type_and_metadata(coords, block_type, metadata)
      section_num, section_x, section_y, section_z = convert_coords(coords)
      
      block_type_offset = 256*section_y + 16*section_z + section_x
      @block_type[section_num][block_type_offset] = block_type.to_i.chr
      
      metadata_offset = 128*section_y + 8*section_z + section_x/2
      nibble = section_x % 2
      @metadata[section_num][metadata_offset] = if nibble == 1
        (@metadata[section_num][metadata_offset].ord & 0x0F) | (metadata << 4 & 0xF0)
      else
        (@metadata[section_num][metadata_offset].ord & 0xF0) | (metadata & 0xF)
      end.chr
    end
    
    # block_type can be an object like ItemType::Air, nil (for unknown), or just an integer
    def count_block_type(block_type)
      block_type_data.bytes.count block_type ? block_type.to_i : 255
    end
    
    protected 
    # returns a string 4096 bytes long with all the block type data for this chunk
    def block_type_data
      @block_type.join
    end
    
    def get_nibble(dataz, coords)
      section_num, section_x, section_y, section_z = convert_coords(coords)
      offset = 128*section_y + 8*section_z + section_x/2
      section = dataz[section_num]
      
      if section.nil?
        raise "NO SECTION #{section_num}"
      end
      
      section[offset].ord >> ((section_x % 2) * 4) & 0x0F
    end
    
  end

  class ChunkTracker
    include Uninspectable
  
    attr_reader :chunks
  
    def initialize(client)
      @change_listeners = []
      @chunks = {}

      client.listen do |p|
        # puts Time.now.strftime("%M:%S.%L") + " " + p.inspect

        if p.respond_to?(:chunk_id)
          # Apply change
          if p.respond_to?(:deallocation?) && p.deallocation?
            unload_chunk p.chunk_id
          else
            get_or_create_chunk(p.chunk_id).apply_packet p
          end
          
          # Notify listeners
          notify_change_listeners p.chunk_id, p
          
        elsif p.is_a?(Packet::MapChunkBulk)

          # Apply all changes
          stream = StringIO.new(p.data)
          p.metadata.each do |chunk_id, primary_bit_map, add_bit_map|
            get_or_create_chunk(chunk_id).apply_broad_change(true, primary_bit_map, add_bit_map, stream)
          end
          
          # Notify the listeners for each chunk that changed
          p.metadata.each do |chunk_id, _1, _2|
            notify_change_listeners chunk_id, p
          end
        end
      end
    end
    
    # coords is a RedstoneBot::Coords object or an array of numbers
    def block_type(coords)
      coords = coords.collect &:floor   # make array of ints

      return ItemType::Air if coords[1] > 255   # treat spots above the top of the world as air
      return ItemType::Bedrock if coords[1] < 0 # treat spots below the top of the world as bedrock
      
      chunk = chunk_at(coords)
      chunk && ItemType.from_id(chunk.block_type_id(coords))
    end
    
    # coords is a RedstoneBot::Coords object or an array of numbers
    def block_metadata(coords)
      coords = coords.collect &:floor
      return 0 if coords[1] > 255 || coords[1] < 0
      chunk = chunk_at(coords)
      chunk && chunk.block_metadata(coords)
    end
        
    def change_block(coords, block_type, metadata=0)
      chunk = chunk_at(coords)
      if chunk
        chunk.set_block_type_and_metadata(coords, block_type, metadata)
        notify_change_listeners chunk.id, nil
      end
    end
    
    # coords is a RedstoneBot::Coords object or an array of numbers.  The y value is ignored.
    def chunk_id_at(coords)
      [coords[0].floor/16*16, coords[2].floor/16*16]
    end

    def chunk_at(coords)
      @chunks[chunk_id_at(coords)]
    end
    
    def on_change(&proc)
      @change_listeners << proc
    end
    
    def loaded_chunks
      @chunks.values
    end
    
    protected

    def get_or_create_chunk(chunk_id)
      @chunks[chunk_id] ||= Chunk.new(chunk_id)
    end
    
    def unload_chunk(chunk_id)
      chunk = @chunks.delete(chunk_id)
      chunk.unload if chunk
    end
    
    def notify_change_listeners(*args)
      @change_listeners.each do |l|
        l.call(*args)
      end
    end
  end

end