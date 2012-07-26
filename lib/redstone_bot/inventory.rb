require_relative "packets"
require_relative "entities"

module RedstoneBot
  class InventorySlot < Struct.new(:item_type, :count, :damage)
  end

  class Inventory
    def initialize(client)
      @client = client
      @data = []
      
      client.listen do |p|
        case p
        when Packet::SetWindowItems, Packet::SetSlot
        then
          puts "#{@client.time_string} #{p.inspect}"
        end
      end
      
      client.listen do |p|
        case p
        when Packet::SetWindowItems
          if p.window_id == 0
            @data = p.slots_data.collect do |slot_data|
              if slot_data[:item_id] < 0
                nil
              else
                item_type = ItemType.from_id(slot_data[:item_id])
                raise "Unknown item type #{slot_data[:item_id]}." if !item_type
                InventorySlot.new(item_type, slot_data[:count], slot_data[:damage])
              end
            end
          end
          puts @data.inspect  # tmphax
        end
      end
    end
    
  end
end