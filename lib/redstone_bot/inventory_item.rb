require_relative "pack"

module RedstoneBot
  class InventoryItem < Struct.new(:item_type, :count, :damage, :enchant_data)
    include DataEncoder
    
    def encode_data
      binary_data = [item_type.id, count, damage].pack("s>CS>")
      binary_data += if enchant_data
        [enchant_data.size].pack("S>") + enchant_data
      else
        short(-1)
      end
      binary_data
    end
  end
end