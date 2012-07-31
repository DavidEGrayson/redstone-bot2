require_relative "packets"
require_relative "item_types"

module RedstoneBot

  class Inventory
    attr_accessor :debug
    
    NormalSlotRange = 9..35
    HotbarSlotRange = 36..44
    
    # TODO: handle the packet that says you picked up an item
    
    def reset
      @loaded = false
      @slots = [nil]*45
      @pending_actions = []
    end
    
    def initialize(client)
      @client = client
      @selected_hotbar_slot_index = 0
      reset
      
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
            @slots = p.slots   # assumption: no other objects will be messing with the same array
            @loaded = true
          end
        when Packet::ConfirmTransaction
          expected_action_number = @pending_actions.first
          if p.action_number != expected_action_number
            raise "Unexpected transaction confirmation from server.  Expected action number = #{expected_action_number}.  Actual = #{p.action_number}."
          end
          if p.accepted
            @pending_actions.shift
          else
            # Our transaction was rejected, probably due to lag.  The server will send a SetWindowItems
            # to tell us our entirey inventory, and until then lets us treat it as unloaded.
            reset
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
    
    def pending?
      !(loaded? && @pending_actions.empty?)
    end
    
    def item_types
      non_empty_slots.collect(&:item_type).uniq
    end
    
    def include?(item_type)
      slots.any? { |s| item_type === s }
    end
    
    def selected_slot
      slots[HotbarSlotRange.min + @selected_hotbar_slot_index]
    end
    
    def count(item_type)
      slots_of_type(item_type).inject(:+){ |sum, slot| slot.count }
    end
    
    def select(item_type)
      return false if !loaded?
    
      # TODO: it item_type is nil, actually put nothing in your arms (and return false if all slots are full)
    
      if hotbar_slot_index = hotbar_slots.index { |slot| item_type === slot }
        puts "Found #{item_type} in hotbar slot #{hotbar_slot_index}." if debug
        select_hotbar_slot(hotbar_slot_index)
        return true
        
      elsif slot_index = normal_slots.index { |slot| item_type === slot }
        # TODO: also look for items in the armor slots!
        
        puts "Found #{item_type} in normal slot #{slot_index}." if debug
        
        if hotbar_slot_index = hotbar_slots.find_index { |s| s.nil? }        
          puts "Putting into hotbar slot #{hotbar_slot_index}." if debug

          # Assumption: choose_hotbar_slot chose the FIRST empty slot, so we can just
          # shift_click the get the item into that slot.
          src_slot_id = NormalSlotRange.min + slot_index
          destination_slot_id = HotbarSlotRange.min + hotbar_slot_index
          send_shift_click src_slot_id
          swap_slots src_slot_id, destination_slot_id
          
          select_hotbar_slot(hotbar_slot_index)
          return true
          
        else
          raise "Hotbar is full: need to do some left clicking and write tests!"          
        end
      else
        puts "Item #{item_type} not found." if debug
        return false
      end
    end
    
    # TODO: protected
    def swap_slots(x, y)
      slots[x], slots[y] = slots[y], slots[x]
    end
        
    def hotbar_include?(item_type)
      hotbar_slots.any? { |s| item_type === s }      
    end
    
    def slots_of_type(item_type)
      slots.select{ |s| item_type === s }
    end
    
    # hotbar_slot_index must be a number in 0..8, which corresponds to inventory slot IDs 36..44
    def select_hotbar_slot(hotbar_slot_index)
      if hotbar_slot_index != @selected_hotbar_slot_index
        puts "Selecting hotbar slot #{hotbar_slot_index}." if debug
        @selected_hotbar_slot_index = hotbar_slot_index
        @client.send_packet Packet::HeldItemChange.new @selected_hotbar_slot_index
      else
        puts "Hotbar slot #{hotbar_slot_index} already selected." if debug
      end
    end

    def send_shift_click(slot_id) 
      puts "Shift clicking slot #{slot_id} #{slots[slot_id]}" if debug
      action_number = new_transaction
      @client.send_packet Packet::ClickWindow.new(0, slot_id, false, action_number, true, slots[slot_id])
    end
    
    def new_transaction
      action_number = @client.next_action_number
      @pending_actions.push action_number
      return action_number
    end
    
    def slots
      @slots
    end
        
    def normal_slots
      slots[NormalSlotRange]
    end
    
    def hotbar_slots
      slots[HotbarSlotRange]
    end
    
    def non_empty_slots
      slots.select { |s| !s.nil? }
    end
  end
end