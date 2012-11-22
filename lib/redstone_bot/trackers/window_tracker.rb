require_relative '../packet_printer'

module RedstoneBot
  class WindowTracker
    attr_reader :window_id, :window_title, :slots
      
    WindowTypes = {
      "container.chest" => :chest,
      "container.chestDouble" => :chest_double
    }
    
    def reset
      @window_id = nil
      @window_title = nil
      @slots = nil
      @pending_actions = []
    end
    
    def initialize(client)
      reset
    
      @client = client
      @client.listen { |p| receive_packet p }
    end

    # open? is probably not very useful; use loaded? instead
    def open?
      @window_id ? true : false
    end
    
    def loaded?
      @slots ? true : false
    end

    def receive_packet(packet)
      return unless packet.respond_to?(:window_id)
      
      case packet
      when Packet::OpenWindow
        @window_id = packet.window_id
        @window_title = WindowTypes[packet.title]
      when Packet::CloseWindow
        reset
      when Packet::SetWindowItems
        return if packet.window_id != @window_id
        @slots = packet.slots   # assumption: no other objects will be messing with the same array
      when Packet::SetSlot
        return if packet.window_id != @window_id
        @slots[packet.slot_id] = packet.slot
      end
    end
    
    def new_transaction
      action_number = @client.next_action_number
      @pending_actions.push action_number
      action_number
    end
    
    # A handy function for unit testing.
    def <<(packet)
      receive_packet(packet)
    end

    def dump_slot_id(id)
      raise "Window is not loaded yet" if !loaded?
      if slots[id] != nil
        @client.send_packet Packet::ClickWindow.new(window_id, id, :left, new_transaction, false, slots[id])
        # @client.send_packet Packet::ClickWindow.outside(new_transaction)
        @client.send_packet Packet::ClickWindow.new window_id, -999, :left, new_transaction, false, nil
        slots[id] = nil
      end
    end
    
  end

end