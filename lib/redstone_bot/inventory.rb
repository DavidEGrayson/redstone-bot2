require_relative "packets"
require_relative "item_types"

module RedstoneBot

  class Inventory  
    attr_reader :slots
    
    def initialize(client)
      @client = client
      @slots = [nil]*45
      @loaded = false
            
      client.listen do |p|
        case p
        when Packet::SetWindowItems, Packet::SetSlot, Packet::ConfirmTransaction, Packet::UpdateWindowProperty
        then
          puts "#{@client.time_string} #{p.inspect}"
        end
      end if false
      
      client.listen do |p|
        case p
        when Packet::SetWindowItems
          if p.window_id == 0
            if p.slots.size != 45
              raise "Error: Expected 44 slots in inventory, received #{p.slots_data.size}."
            end
            @slots = p.slots
            @loaded = true
          end
        end
      end
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
      slots[9..35]
    end
    
    def hotbar_slots
      slots[36..44]
    end
    
    def shift_click_slot(slot_id) 
      puts "shift clicking slot #{slot_id} #{slots[slot_id]}"
      @client.send_packet Packet::ClickWindow.new(0, slot_id, false, @client.next_action_number, true, slots[slot_id])
    end
    
    def select_slot(slot_id)
      @client.send_packet Packet::HeldItemChange.new(slot_id)
    end
    
  end
end