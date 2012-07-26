require_relative "packets"
require_relative "entities"

module RedstoneBot
  class Slot
    attr_reader :item_id, :count, :damage
    
    def initialize(opts)
      @item_id = opts[:item_id]
      @count = opts[:count]
    end
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
                Item.create(slot_data[:item_id], nil, slot_data[:count], slot_data[:damage])
              end
            end
          end
          puts @data.inspect
        end
      end
    end
  end
end