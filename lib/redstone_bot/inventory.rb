require_relative "packets"
require_relative "item_types"

module RedstoneBot
  class InventoryItem < Struct.new(:item_type, :count, :damage)
  end

  class Inventory  
    attr_reader :slots
    
    def initialize(client)
      @client = client
      @slots = [nil]*45
      @loaded = false
            
      client.listen do |p|
        case p
        when Packet::SetWindowItems, Packet::SetSlot
        then
          puts "#{@client.time_string} #{p.inspect}"
        end
      end if false
      
      client.listen do |p|
        case p
        when Packet::SetWindowItems
          if p.window_id == 0
            if p.slots_data.size != 45
              raise "Error: Expected 44 slots in inventory, received #{p.slots_data.size}."
            end
            @slots = p.slots_data.collect do |slot_data|
              if slot_data
                item_type = ItemType.from_id(slot_data[:item_id])
                raise "Unknown item type #{slot_data[:item_id]}." if !item_type
                InventoryItem.new(item_type, slot_data[:count], slot_data[:damage])
              end
            end
            @loaded = true
          end
        end
      end
    end
    
    def select_slot(slot_id)
      @client.send_packet Packet::HeldItemChange.new(slot_id)
    end
    
    def loaded?
      @loaded
    end
    
    def empty?
      slots.none?
    end
    
    def include?(item_type)
      slots.any? { |s| item_type === s }
    end
    
    def hotbar_include?(item_type)
      hotbar_slots.any? { |s| item_type === s }      
    end

    def normal_slots
      @slots[9..35]
    end
    
    def hotbar_slots
      @slots[36..44]
    end
    
  end
end