require_relative '../packet_printer'

module RedstoneBot
  class WindowTracker
    PrintPacketClasses = [
      Packet::OpenWindow, Packet::CloseWindow, Packet::SetWindowItems, Packet::SetSlot, Packet::UpdateWindowProperty, Packet::ConfirmTransaction
    ]
    
    def initialize(client)
      # for debugging
      @packet_printer = PacketPrinter.new(client, PrintPacketClasses)
      
      client.listen do |p|
        next unless p.respond_to?(:window_id)
      end
   
    end
  end

end