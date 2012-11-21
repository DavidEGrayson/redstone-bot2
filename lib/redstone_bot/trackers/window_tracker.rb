require_relative '../packet_printer'

module RedstoneBot
  class WindowTracker
    attr_reader :window_id, :window_title, :slots
  
    PrintPacketClasses = [
      Packet::OpenWindow, Packet::CloseWindow, Packet::SetWindowItems, Packet::SetSlot, Packet::UpdateWindowProperty, Packet::ConfirmTransaction
    ]
    
    WindowTypes = {
      "container.chest" => :chest,
      "container.chestDouble" => :chest_double
    }
    
    def initialize(client)
      # for debugging
      if client
        @packet_printer = PacketPrinter.new(client, PrintPacketClasses)
        client.listen { |p| receive_packet p } if client
      end
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
        @window_id = @slots = @window_title = nil
      when Packet::SetWindowItems
        return if packet.window_id != @window_id
        @slots = packet.slots   # assumption: no other objects will be messing with the same array
      when Packet::SetSlot
        return if packet.window_id != @window_id
        @slots[packet.slot_id] = packet.slot
      end
    end
    
    # A handy function for unit testing.
    def <<(packet)
      receive_packet(packet)
    end

  end

end