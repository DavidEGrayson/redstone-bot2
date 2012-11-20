require_relative '../packet_printer'

module RedstoneBot
  class WindowTracker
    attr_reader :window_id
  
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
      end
    end
    
    # A handy function for unit testing.
    def <<(packet)
      receive_packet(packet)
    end

  end

end