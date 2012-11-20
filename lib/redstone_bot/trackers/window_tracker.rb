require_relative '../packet_printer'

module RedstoneBot
  class WindowTracker
    attr_reader :window_id, :slots
  
    PrintPacketClasses = [
      Packet::OpenWindow, Packet::CloseWindow, Packet::SetWindowItems, Packet::SetSlot, Packet::UpdateWindowProperty, Packet::ConfirmTransaction
    ]
    
    def initialize(client)
      # for debugging
      if client
        @packet_printer = PacketPrinter.new(client, PrintPacketClasses)
        client.listen { |p| receive_packet p } if client
      end
    end

    def open?
      @window_id ? true : false
    end
    
    def receive_packet(packet)
      return unless packet.respond_to?(:window_id)
      
      case packet
      when Packet::OpenWindow
        @window_id = packet.window_id
      when Packet::CloseWindow
        @window_id = nil
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