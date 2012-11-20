require_relative '../packet_printer'

module RedstoneBot
  class WindowTracker
    PrintPacketClasses = [
      Packet::OpenWindow, Packet::CloseWindow, Packet::SetWindowItems, Packet::SetSlot, Packet::UpdateWindowProperty, Packet::ConfirmTransaction
    ]
    
    def initialize(client)
      @open = false
    
      # for debugging
      if client
        @packet_printer = PacketPrinter.new(client, PrintPacketClasses)
        client.listen { |p| receive_packet p } if client
      end
    end
        
    def open?
      @open
    end
    
    def receive_packet(packet)
      return unless p.respond_to?(:window_id)
    end
    
    # A handy function for unit testing.
    def <<(packet)
      receive_packet(packet)
    end

  end

end