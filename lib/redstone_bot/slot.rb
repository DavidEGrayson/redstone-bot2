module RedstoneBot
  class Slot < Struct.new(:item_type, :count, :damage, :enchant_data)
    def initialize(item_type, count=1, damage=0, enchant_data=nil)
      self.item_type = item_type
      self.count = count
      self.damage = damage
      self.enchant_data = enchant_data
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
        self.enchant_data = stream.read(enchant_data_len)
      end
      self
    end
    
    def encode_data
      raise inspect if item_type.nil?  # TMPHAX
      
      binary_data = [item_type.id, count, damage].pack("s>CS>")
      binary_data += if enchant_data
        [enchant_data.size].pack("S>") + enchant_data
      else
        "\xFF\xFF"  # length is short(-1)
      end
      binary_data
    end
    
  end
end