module RedstoneBot
  class Slot < Struct.new(:item_type, :count, :damage, :enchant_data)
    def self.receive_data(stream)
      s = allocate
      s.receive_data(stream)
      s
    end
    
    def receive_data(stream)
      item_id = stream.read_short
      return if item_id == -1
      @item_type = ItemType.from_id(item_id)      
      raise "Unknown item type #{item_id}." if !@item_type      
      @count = stream.read_byte
      @damage = stream.read_unsigned_short
      enchant_data_len = stream.read_short
      if enchant_data_len > 0
        @enchant_data = stream.read(enchant_data_len)
      end
    end
    
    def encode_data
      binary_data = [item_type.id, count, damage].pack("s>CS>")
      binary_data += if enchant_data
        [enchant_data.size].pack("S>") + enchant_data
      else
        "\xFF\xFF"
      end
      binary_data
    end
    
    def empty?
      @item_type.nil?
    end
  end
end