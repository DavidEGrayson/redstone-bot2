require 'zlib'

require_relative 'item_types'

module RedstoneBot
  # This class represents an item, for example in the inventory, on the ground, or
  # being held by an entity.
  # Item objects are immutable (frozen) after they are created.
  class Item < Struct.new(:item_type, :count, :damage, :enchant_data)
    def initialize(item_type, count=1, damage=0, enchant_data=nil)
      self.item_type = item_type
      self.count = count
      self.damage = damage
      self.enchant_data = enchant_data.freeze      
      
      immutable!
    end
    
    def immutable!
      enchant_data.freeze
      freeze
    end
  
    def self.receive_data(stream)
      allocate.receive_data(stream)      
    end
    
    def self.encode_data(slot)
      if slot
        slot.encode_data
      else
        "\xFF\xFF" # item_type is short(-1)
      end
    end
    
    def receive_data(stream)
      item_id = stream.read_short
      return nil if item_id == -1
      self.item_type = ItemType.from_id(item_id)
      raise "Unknown item type #{item_id}." if !item_type      
      self.count = stream.read_byte
      self.damage = stream.read_unsigned_short
      enchant_data_len = stream.read_short
      if enchant_data_len > 0
        compressed_data = stream.read(enchant_data_len)
        nbt_stream = Zlib::GzipReader.new(StringIO.new compressed_data).extend DataReader
        self.enchant_data = nbt_stream.read_nbt
      end
      
      immutable!
      self
    end
    
    def encode_data
      binary_data = [item_type, count, damage].pack("s>CS>")
      binary_data += if enchant_data
        nbt = NbtEncoderForEnchantData.nbt(enchant_data)
        sio = StringIO.new
        writer = Zlib::GzipWriter.new(sio)
        writer.write nbt
        writer.close
        compressed_data = sio.string.force_encoding('BINARY')
        
        # Set some metadata so that our comrpessed data will be the same as the server's.
        compressed_data[4..7] = "\x00\x00\x00\x00"  # set the mtime to 0
        compressed_data[9] = "\x00"  # set os_code to 0
        
        [compressed_data.size].pack("S>") + compressed_data
      else
        "\xFF\xFF"  # length is short(-1)
      end
      binary_data
    end
    
    # Returns a new item with the specified quantity removed.
    def -(num)
      self + (-num)
    end
    
    def +(num)
      return self if num.zero?    
      self.class.new(item_type, count + num, damage, enchant_data) if (count + num) > 0    
    end
    
    def free_space
      item_type.max_stack - count
    end
    
    def stacks_with?(other)
      other && self.item_type == other.item_type && self.damage == other.damage && item_type.stackable?
    end
    
    # Tries to stack this item with another item.
    # Returns [stack, leftovers].
    def try_stack(other)
      if stacks_with?(other)
        transfer_quantity = [self.free_space, other.count].min
        [self + transfer_quantity, other - transfer_quantity]
      else
        [self, other]
      end
    end
    
    def ===(other)
      self == other or other.respond_to?(:item) && self == other.item
    end
    
    def to_s
      s = item_type.to_s
      s += "*#{count}" if count != 1
      
      details = []
      details << "damage=#{damage}" if damage != 0
      details << "enchant_data=#{enchant_data.inspect}" if enchant_data      
      s += "(" + details.join(" ") + ")" if !details.empty?
      
      s
    end
    
  end
end